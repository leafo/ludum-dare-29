
{graphics: g} = love

class Enemy extends Entity
  is_enemy: true
  w: 40
  h: 20

  health: 20
  max_health: 20

  facing: "left"

  new: (...) =>
    super ...
    @accel = Vec2d!
    @seqs = DrawList!

  take_hit: (p, world) =>
    return if @stunned
    power = 5000

    world.viewport\shake!

    @health -= 10

    @stunned = @seqs\add Sequence ->
      dir = (Vec2d(@center!) - Vec2d(p\center!))\normalized!
      dir[2] = dir[2] * 2
      @accel = dir\normalized! * power

      wait 0.1
      @accel = Vec2d!
      wait 0.5
      @stunned = false

  update: (dt, world) =>
    @seqs\update dt

    dampen_vector @vel, dt * 2000
    @vel\adjust unpack @accel * dt
    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = -@vel[1] / 2

    if cy
      @vel[2] = -@vel[2] / 2

    @health > 0

  draw: =>
    color = if @stunned
      {255,200,200}
    else
      {255,255,255}

    super color

{ :Enemy }
