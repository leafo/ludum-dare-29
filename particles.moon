
{ graphics: g } = love

class Blood extends PixelParticle
  size: 50
  life: 2

  new: (@x, @y) =>
    @size = rand 20,50
    @vel = Vec2d.random! * rand(20, 40)
    @accel = Vec2d 0, 0

  draw: =>
    t = ad_curve (1 - @life / @@life), 0, 0.05, 0.8

    COLOR\push {80,10,10, t * 128}
    super!
    COLOR\pop!

  update: (dt) =>
    dampen_vector @vel, dt * 10
    super dt

class Bubble extends PixelParticle
  size: 3
  life: 10.0

  new: (@x, @y) =>
    @size = rand 2,5
    @vel = Vec2d(0, -rand(15,30))\random_heading!
    @offset = rand(0, 10)
    @accel = Vec2d 0, -rand(35,45)

  update: (dt) =>
    @accel[1] = math.sin(@offset + @life * 8) * 100
    super dt

class BubbleEmitter extends Emitter
  spread_x: 8
  spread_y: 8

  count: 30
  duration: 0.5
  make_particle: (x, y) =>
    x += rand -@spread_x, @spread_x
    y += rand -@spread_y, @spread_y

    Bubble x,y


class BloodEmitter extends Emitter
  count: 4
  duration: 0.5
  make_particle: (x, y) =>
    Blood x,y

{
  :BubbleEmitter
  :BloodEmitter
}
