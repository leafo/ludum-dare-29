
{graphics: g} = love

import BloodEmitter from require "particles"

class Enemy extends Entity
  is_enemy: true
  w: 40
  h: 20

  slowing: 0

  health: 20*100
  max_health: 20

  facing: "left"

  new: (...) =>
    super ...
    @seqs = DrawList!

    @seqs\add Sequence ->
      if @stunned
        wait_until -> not @stunned

      toward_player = @vector_to @world.player
      dist_to_player = toward_player\len!
      left_of_player = toward_player[1] > 0

      switch pick_dist {
        move: 1
        attack: 1
      }
        when "move"
          print "moving"
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

          switch pick_dist {
            move: 1
            charge: 1
          }
            when "charge"
              await @\charge, dir
            when "move"
              await @\move, dir
        when "attack"
          await @\attack, @world.player

      wait 0.5
      again!

  move: (dir, fn) =>
    speed = 250
    @seqs\add Sequence ->
      @slowing -= 1
      @move_accel = dir * speed
      wait 0.15
      @move_accel = false
      wait 1.0
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

    ax, ay = 0,0

    if update_accel = @stun_accel or @move_accel
      ax += update_accel[1]
      ay += update_accel[2]

    if @slowing >= 0
      dampen_vector @vel, dt * 100 * (@slowing * 2 + 1)

    @vel\adjust ax * dt, ay * dt
    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = -@vel[1] / 2

    if cy
      @vel[2] = -@vel[2] / 2

    @health > 0


  take_hit: (p, world) =>
    return if @stunned
    power = 3000

    world.viewport\shake!
    world.particles\add BloodEmitter world, @center!

    @health -= 10

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
    color = if @stunned
      {255,200,200}
    elseif @move_accel
      {20,20,20}
    else
      {255,255,255}

    super color

    if @slowing != 0
      g.print "Slowing #{@slowing}", @x, @y


{ :Enemy }
