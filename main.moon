require "lovekit.all"

{graphics: g} = love

class Player extends Entity
  speed: 200
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
    @accel = CONTROLLER\movement_vector @speed * dt
    decel = @speed * dt

    if @accel[1] != 0
      @facing = @accel[1] > 0 and "right" or "left"

    if @accel[1] == 0
      -- not moving in x, shrink it
      @vel[1] = dampen @vel[1], decel

    if @accel[2] == 0
      @vel[2] = dampen @vel[2], decel

    @vel\adjust unpack @accel * dt * @speed
    @vel\cap @max_speed

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = 0

    if cy
      @vel[2] = -@vel[2] / 2

    true

class Ocean
  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @entities = DrawList!

    @bounds = Box 0,0, 1000, 1000

    @player = Player 20, 20
    @entities\add @player

    @viewport\center_on @player

  draw: =>

    @viewport\apply!
    @bounds\draw {255,255,255,20}

    @entities\draw!

    @viewport\pop!

  collides: (thing) =>
    not @bounds\contains_box thing

  update: (dt) =>
    @viewport\center_on @player, nil, dt
    @entities\update dt, @

love.load = ->
  export CONTROLLER = Controller GAME_CONFIG.keys
  export DISPATCHER = Dispatcher Ocean!

  DISPATCHER\bind love

