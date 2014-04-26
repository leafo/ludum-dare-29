
{ graphics: g } = love

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

{
  :BubbleEmitter
}
