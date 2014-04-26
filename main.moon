require "lovekit.all"

{graphics: g} = love

class Player extends Entity
  speed: 200

  update: (dt, world) =>
    dx, dy = unpack CONTROLLER\movement_vector dt * @speed
    @move dx, dy
    true

class Game
  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @entities = DrawList!

    @player = Player 20, 20
    @entities\add @player

  draw: =>
    @viewport\apply!
    g.print "hello world", 10, 10

    @entities\draw!

    @viewport\pop!

  update: (dt) =>
    @entities\update dt

love.load = ->
  export CONTROLLER = Controller GAME_CONFIG.keys

  export DISPATCHER = Dispatcher Game!
  DISPATCHER\bind love

