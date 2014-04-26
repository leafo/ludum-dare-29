
import BubbleEmitter from require "particles"

{graphics: g} = love

class Player extends Entity
  is_player: true
  speed: 200
  max_speed: 100
  facing: "right"

  health: 100
  max_health: 100

  w: 40
  h: 20

  new: (...) =>
    super ...
    @seqs = DrawList!

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

  update_mouth: =>
    @mouth_box or= Box @x, @y, 10, 10
    @mouth_box.y = @y + (@h - @mouth_box.w) / 2
    @mouth_box.x = if @facing == "right"
      @x + @w - @mouth_box.w
    else
      @x

  update: (dt, world) =>
    @seqs\update dt, world

    @accel = CONTROLLER\movement_vector @speed
    decel = @speed / 100

    if @attacking
      @accel[1] = @attack_accel[1]
    else
      if @accel[1] != 0
        @facing = @accel[1] > 0 and "right" or "left"

    if @stunned
      @accel[1], @accel[2] = unpack @stun_accel

    if @accel[1] == 0
      -- not moving in x, shrink it
      @vel[1] = dampen @vel[1], decel

    if @accel[2] == 0
      @vel[2] = dampen @vel[2], decel

    -- apply the ocean
    if @accel\is_zero!
      world\gravity @vel, dt

    @vel\adjust unpack @accel * dt
    @vel\cap @max_speed unless @attacking

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = 0

    if cy
      @vel[2] = -@vel[2] / 2

    if @mouth_emitter
      @mouth_emitter.x, @mouth_emitter.y = @mouth_box\center!

    @update_mouth!

    true

  draw: =>
    super!
    color = if @attacking
      {255,0, 0, 128}
    elseif @stunned
      {255,0, 255, 128}
    else
      {0,255, 0, 128}

    COLOR\push color
    @mouth_box\draw!
    COLOR\pop!

  take_hit: (enemy, world) =>
    if @attacking
      if @mouth_box\touches_box enemy
        enemy\take_hit @, world
      return

    return if @stunned
    knockback = 2000
    world.viewport\shake nil, nil, 2

    @stunned = @seqs\add Sequence ->
      @health -= 15

      dir = (Vec2d(@center!) - Vec2d(enemy\center!))\normalized!

      @vel[1] = @vel[1] / 2
      @vel[2] = @vel[2] / 2
      @stun_accel = dir * knockback
      wait 0.075
      @stun_accel = Vec2d!
      wait 0.3
      @stunned = false


{ :Player }
