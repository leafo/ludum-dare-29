require "lovekit.all"

{graphics: g} = love

class Player extends Entity
  speed: 200
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
    dx, dy = unpack CONTROLLER\movement_vector dt * @speed
    if dx != 0
      @facing = dx > 0 and "right" or "left"

    @fit_move dx, dy, world
    true

class Ocean
  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @entities = DrawList!

    @bounds = Box 0,0, 100, 100

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

