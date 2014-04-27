
{graphics: g} = love

import BubbleEmitter, BloodEmitter from require "particles"
import FadeAway from require "misc"

class BoostEmitter extends BubbleEmitter
  count: 5
  duration: 0.5

  spread_x: 5
  spread_y: 1


class Player extends Entity
  is_player: true
  speed: 200
  max_speed: 100
  facing: "right"

  health: 100

  lazy sprite: -> Spriter "images/player.png", 50, 30

  w: 30
  h: 10

  ox: 10
  oy: 8

  new: (...) =>
    super ...
    @seqs = DrawList!
    @effects = EffectList!

    with @sprite
      @anim = StateAnim "right", {
        left: \seq {
          0,1,2,3
        }, 0.4, true

        right: \seq {
          0,1,2,3
        }, 0.4

        left_attacking: \seq {
          4,5,6,7
        }, 0.4, true

        right_attacking: \seq {
          4,5,6,7
        }, 0.4
      }

    @update_mouth!

  looking_at: (viewport) =>
    cx, cy = @center!
    switch @facing
      when "left"
        cx -= viewport.w / 10
      when "right"
        cx += viewport.w / 10

    cx, cy

  attack: (world) =>
    return if @stunned
    return if @attacking or @attacking_cooloff
    attack_force = 2500

    @mouth_emitter = BubbleEmitter world, @mouth_box\center!
    world.particles\add @mouth_emitter
    AUDIO\play "charge"

    @attacking = @seqs\add Sequence ->
      @vel[1] = 0

      force = attack_force
      force = -force if @facing == "left"

      @attack_accel = Vec2d force, 0

      wait 0.2
      @attack_accel = Vec2d -force/2, 0
      wait 0.2

      @attacking = false
      @attacking_cooloff = true
      wait 0.5
      @attacking_cooloff = false

  tail_center: =>
    x,y = @center!
    if @facing == "left"
      x += @w/2

    if @facing == "right"
      x -= @w/2

    x,y

  update_mouth: =>
    @mouth_box or= Box @x, @y, 10, 10
    @mouth_box.y = @y + (@h - @mouth_box.w) / 2
    @mouth_box.x = if @facing == "right"
      @x + @w - @mouth_box.w
    else
      @x

    if @mouth_emitter
      @mouth_emitter.x, @mouth_emitter.y = @mouth_box\center!

    if @boost_emitter
      @boost_emitter.x, @boost_emitter.y = @tail_center!

  update: (dt, world) =>
    @strafing = CONTROLLER\is_down "attack"
    if CONTROLLER\tapped "attack"
      @attack world

    @seqs\update dt, world
    @effects\update dt, world

    @accel = CONTROLLER\movement_vector @speed
    decel = @speed / 100

    dtu, dtd, dtl, dtr = CONTROLLER\double_tapped "up", "down", "left", "right"

    if (dtu or dtd or dtl or dtr) and not @boosting
      boost_power = 1000
      AUDIO\play "boost"
      @boosting = @seqs\add Sequence ->
        @boost_emitter = world.particles\add BoostEmitter world, @tail_center!

        xx = dtl and -1 or (dtr and 1) or 0
        yy = dtu and -1 or (dtd and 1) or 0

        @boost_accel = Vec2d  xx * boost_power, yy * boost_power
        wait 0.1
        @boost_accel = false
        wait 0.3
        @boosting = false

    if @attacking
      @accel[1] = @attack_accel[1]
    elseif @stunned
      @accel[1], @accel[2] = unpack @stun_accel
    else
      if @accel[1] != 0 and not @strafing
        @facing = @accel[1] > 0 and "right" or "left"

      if @boost_accel
        @accel[1] += @boost_accel[1]
        @accel[2] += @boost_accel[2]

    if @accel[1] == 0
      -- not moving in x, shrink it
      @vel[1] = dampen @vel[1], decel

    if @accel[2] == 0
      @vel[2] = dampen @vel[2], decel

    -- apply the ocean
    if @accel\is_zero!
      world\gravity @vel, dt

    @vel\adjust unpack @accel * dt
    unless @attacking or @boosting
      @vel\cap @max_speed

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if (cx or cy) and not @hit_audio
      @hit_audio = @seqs\add Sequence ->
        AUDIO\play "bump_wall"
        wait 0.2
        @hit_audio = nil

    if cx
      @vel[1] = 0

    if cy
      @vel[2] = -@vel[2] / 2

    @update_mouth!
    state = @facing
    if @attacking
      state = "#{state}_attacking"

    @anim\set_state state
    speed = @vel\len!

    @anim\update dt * (1 + speed / 100)
    alive = @health > 0

    unless alive
      world.particles\add BloodEmitter world, @center!
      world.particles\add FadeAway @
      AUDIO\play "player_die"

      world.particles\add Sequence ->
        import GameOver from require "screens"
        wait 1.0
        DISPATCHER\replace GameOver world.game

    alive

  draw: =>
    Box.outline @

    @effects\before!
    @anim\draw @x - @ox, @y - @oy
    @effects\after!

    color = if @attacking
      {255,0, 0, 128}
    elseif @stunned
      {255,0, 255, 128}
    else
      {0,255, 0, 128}

    COLOR\push color
    @mouth_box\outline!
    COLOR\pop!

  take_hit: (enemy, world) =>
    if enemy.is_transport
      enemy\take_hit @, world
      return

    if @attacking
      if @mouth_box\touches_box enemy
        enemy\take_hit @, world
      return

    return if @stunned
    knockback = 2000
    world.viewport\shake nil, nil, 2
    @effects\add FlashEffect!
    AUDIO\play "hit1"

    @stunned = @seqs\add Sequence ->
      @health = math.max 0, @health - 15
      dir = enemy\vector_to(@)\normalized!

      @vel[1] = @vel[1] / 2
      @vel[2] = @vel[2] / 2
      @stun_accel = dir * knockback
      wait 0.075
      @stun_accel = Vec2d!
      wait 0.3
      @stunned = false

  __tostring: =>  "<Player #{Box.__tostring @}>"

{ :Player }
