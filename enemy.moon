
{graphics: g} = love

import BubbleEmitter, BloodEmitter from require "particles"
import FadeAway from require "misc"

class Enemy extends Entity
  score: 1

  is_enemy: true
  w: 40
  h: 20

  ox: 0
  oy: 0

  slowing: 0
  threat: 0

  health: 1

  facing: "left"

  move_speed: 250
  move_time: 1.0

  new: (...) =>
    super ...
    @seqs = DrawList!
    @effects = EffectList!
    @seqs\add @make_ai!

  make_ai: =>
    error "implement ai for enemy #{@@__name}"

  move: (dir, fn) =>
    @seqs\add Sequence ->
      @slowing -= 1
      @move_accel = dir * @move_speed
      wait 0.15 * @move_time
      @move_accel = false
      wait 0.85 * @move_time
      @slowing += 1
      fn!

  charge: (dir, fn) =>
    @seqs\add Sequence ->
      amount = rand 500, 700
      @move_accel = dir * amount
      wait 0.3
      @move_accel = false

      @slowing += 1
      wait 1.0
      @slowing -= 1
      fn!

  attack: (thing, fn) =>
    dir = @vector_to(thing)\normalized!
    attack_force = 4000

    @seqs\add Sequence ->
      await (fn) ->
        @effects\add ShakeEffect 0.5, nil, nil, fn

      @mouth_emitter = BubbleEmitter @world, @mouth_box\center!
      @world.particles\add @mouth_emitter

      @move_accel = dir * attack_force
      wait 0.1
      @move_accel = false
      wait 0.1
      @slowing += 4
      wait 0.9
      @slowing -= 4

      fn!

  update: (dt, world) =>
    @world = world
    @seqs\update dt
    @effects\update dt

    ax, ay = 0,0

    if update_accel = @stun_accel or @move_accel
      ax += update_accel[1]
      ay += update_accel[2]

    if @slowing >= 0
      dampen_vector @vel, dt * 100 * (@slowing * 2 + 1)

    if not @stunned and ax != 0
      @facing = ax > 0 and "right" or "left"

    @vel\adjust ax * dt, ay * dt
    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = -@vel[1] / 2

    if cy
      @vel[2] = -@vel[2] / 2

    @anim\set_state @facing

    speed = @vel\len!
    @anim\update dt * (1 + speed / 100)

    @update_mouth!
    alive = @health > 0
    unless alive
      world.particles\add FadeAway @

    alive

  take_hit: (p, world) =>
    return if @stunned
    @threat = 3
    @just_hit = true
    power = 2500

    world.viewport\shake!
    world.particles\add BloodEmitter world, @center!
    @effects\add FlashEffect!

    @health -= 1

    if @health <= 0
      world.game.score += @score
      AUDIO\play "enemy_die"
    else
      AUDIO\play "hit2"

    @stunned = @seqs\add Sequence ->
      dir = p.mouth_box\vector_to(@)\normalized!
      @stun_accel = dir\normalized! * power
      wait 0.1
      @stun_accel = false

      @slowing += 1
      wait 0.5
      @slowing -= 1

      @stunned = false

  draw: =>
    @effects\before!
    @anim\draw @x - @ox, @y - @oy
    @effects\after!

    -- Box.outline @
    -- color = if @stunned
    --   {255,200,200}
    -- elseif @move_accel
    --   {20,20,20}
    -- else
    --   {255,255,255}

    -- super color

    -- COLOR\push {255, 0, 255, 128}
    -- @mouth_box\draw!
    -- COLOR\pop!

    -- if @slowing != 0
    --   g.print "Slowing #{@slowing}", @x, @y


  update_mouth: =>
    @mouth_box or= Box @x, @y, 10, 10
    @mouth_box.y = @y + (@h - @mouth_box.w) / 2
    @mouth_box.x = if @facing == "right"
      @x + @w - @mouth_box.w
    else
      @x

    if @mouth_emitter
      @mouth_emitter.x, @mouth_emitter.y = @mouth_box\center!

class Guppy extends Enemy
  score: 6

  w: 20
  h: 10

  ox: 14
  oy: 9

  health: 3

  lazy sprite: -> Spriter "images/enemy1.png", 50, 30

  new: (...) =>
    super ...
    with @sprite
      @anim = StateAnim "right", {
        left: \seq {
          0,1,2,3
        }, 0.4, true

        right: \seq {
          0,1,2,3
        }, 0.4
      }

  make_ai: =>
    Sequence ->
      if @stunned
        wait_until -> not @stunned

      toward_player = @vector_to @world.player
      dist_to_player = toward_player\len!

      action = if dist_to_player < 250
        pick_dist { charge: 1, move: 1 }
      else
        pick_dist { charge: 1, move: 3 }

      dir = if dist_to_player < 200 and math.random! < 0.5
        toward_player\normalized!
      else
        Vec2d.random!

      switch action
        when "charge"
          await @\charge, dir
        when "move"
          await @\move, dir

      wait rand 0.5, 0.6
      again!

class Shark extends Enemy
  lazy sprite: -> Spriter "images/enemy2.png", 50, 30
  score: 11

  w: 25
  h: 10

  health: 5

  new: (...) =>
    super ...

    with @sprite
      @anim = StateAnim "right", {
        left: \seq {
          ox: 6
          oy: 12

          0,1,2,3
        }, 0.4, true

        right: \seq {
          ox: 19
          oy: 12

          0,1,2,3
        }, 0.4
      }

  make_ai: =>
    Sequence ->
      if @stunned
        wait_until -> not @stunned

      toward_player = @vector_to @world.player
      dist_to_player = toward_player\len!
      left_of_player = toward_player[1] > 0

      move, attack = switch @threat
        when 0
          100, 1
        when 1
          4, 1
        else
          1, 2

      if @just_hit
        attack = 10*attack
        @just_hit = false

      switch pick_dist { :move, :attack }
        when "move"
          dir = if dist_to_player < 150
            pick_dist {
              left: 1 + (left_of_player and 1 or 0)
              right: 1 + (left_of_player and 0 or 1)
              player: 3
            }
          else
            pick_dist {
              left: 3
              right: 3
              player: 2
            }

          dir = switch dir
            when "left"
              Vec2d -1, 0
            when "right"
              Vec2d 1, 0
            when "player"
              (toward_player)\normalized!

          move, charge = switch @threat
            when 0
              3,1
            when 1
              1,1
            else
              1,3

          switch pick_dist { :move, :charge }
            when "charge"
              await @\charge, dir
            when "move"
              await @\move, dir
        when "attack"
          await @\attack, @world.player

      wait rand 0.4, 0.6
      again!

class Jelly extends Enemy
  score: 4

  w: 15
  h: 15

  ox: 13
  oy: 5

  health: 2

  lazy sprite: -> Spriter "images/enemy3.png", 40, 40

  new: (...) =>
    super ...

    with @sprite
      @anim = StateAnim "right", {
        left: \seq {
          0,1,2,3
        }, 0.4, true

        right: \seq {
          0,1,2,3
        }, 0.4
      }

  make_ai: =>
    Sequence ->
      if @stunned
        wait_until -> not @stunned

      toward_player = @vector_to @world.player
      dist_to_player = toward_player\len!
      left_of_player = toward_player[1] > 0

      dir = if dist_to_player < 150
        pick_dist {
          rand: 1
          player: 3
        }
      else
        pick_dist {
          rand: 2
          player: 1
        }

      dir = switch dir
        when "rand"
          Vec2d.random!
        when "player"
          (toward_player)\normalized!

      await @\move, dir
      wait rand 0.8, 1.1
      again!

class Snake extends Enemy
  lazy sprite: -> Spriter "images/enemy4.png", 50, 30
  score: 4

  w: 30
  h: 8

  ox: 8
  oy: 13

  health: 2

  new: (...) =>
    super ...

    with @sprite
      @anim = StateAnim "right", {
        left: \seq {
          0,1,2,3
        }, 0.4

        right: \seq {
          0,1,2,3
        }, 0.4, true
      }

  make_ai: =>
    Sequence ->
      if @stunned
        wait_until -> not @stunned

      toward_player = @vector_to @world.player
      dist_to_player = toward_player\len!
      left_of_player = toward_player[1] > 0

      dir = if dist_to_player < 200 and math.random! < 0.5
        toward_player\normalized!
      else
        Vec2d.random!

      await @\charge, dir
      wait rand 1.0, 1.2
      again!


class Sardine extends Enemy
  w: 8
  h: 8

  move_speed: 500
  move_time: 0.5

  health: 1

  lazy sprite: -> Spriter "images/enemy5.png", 16, 16

  new: (...) =>
    super ...

    with @sprite
      @anim = StateAnim "right", {
        left: \seq {
          ox: 0
          oy: 4

          0,1,2,3
        }, 0.4

        right: \seq {
          oy: 4
          ox: 4

          0,1,2,3
        }, 0.4, true
      }

  make_ai: =>
    Sequence ->
      if @stunned
        wait_until -> not @stunned

      toward_player = @vector_to @world.player
      dist_to_player = toward_player\len!

      dir = if dist_to_player < 200 and math.random! < 0.5
        toward_player\normalized!
      else
        Vec2d.random!

      await @\move, dir
      wait 0.2
      again!

{ :Enemy, :Guppy, :Shark, :Jelly, :Snake, :Sardine }
