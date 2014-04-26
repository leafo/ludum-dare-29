require "lovekit.all"

{graphics: g} = love

class Player extends Entity
  speed: 20
  max_speed: 1500

  w: 40
  h: 20

  looking_at: (viewport) =>
    cx, cy = @center!
    switch @facing
      when "left"
        cx -= viewport.w / 10
      when "right"
        cx += viewport.w / 10

    cx, cy

  update: (dt, world) =>
    @accel = CONTROLLER\movement_vector @speed
    decel = @speed

    if @accel[1] != 0
      @facing = @accel[1] > 0 and "right" or "left"

    if @accel[1] == 0
      -- not moving in x, shrink it
      @vel[1] = dampen @vel[1], decel / 100

    if @accel[2] == 0
      @vel[2] = dampen @vel[2], decel

    -- apply the ocean
    world\gravity @vel, dt

    @vel\adjust unpack @accel * dt * @speed
    @vel\cap @max_speed

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = 0

    if cy
      @vel[2] = -@vel[2] / 2

    true

class Ocean
  gravity_mag: 200

  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @entities = DrawList!

    @bounds = Box 0,0, 1000, 1000

    @player = Player 20, 20
    @entities\add @player

    @viewport\center_on @player

  draw: =>
    @viewport\apply!
    COLOR\pusha 128
    show_grid @viewport, 20, 20
    COLOR\pop!

    @bounds\draw {255,255,255,20}

    @entities\draw!
    @viewport\pop!

  gravity: (vec, dt) =>
    return unless @gravity_pull
    print @gravity_pull
    vec\adjust unpack @gravity_pull * dt

  collides: (thing) =>
    not @bounds\contains_box thing

  update: (dt) =>
    @_t or= 0
    @_t += dt

    @gravity_pull = Vec2d.from_angle(90 + math.sin(@_t * 2) * 10) * @gravity_mag

    @viewport\center_on @player, nil, dt
    @entities\update dt, @

love.load = ->
  export CONTROLLER = Controller GAME_CONFIG.keys
  export DISPATCHER = Dispatcher Ocean!

  DISPATCHER\bind love

