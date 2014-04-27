require "lovekit.all"
require "lovekit.reloader"

{graphics: g} = love

import Hud, MessageBox from require "hud"
import Player from require "player"
import Guppy, Shark, Jelly, Snake, Sardine from require "enemy"

import Ripple from require "shaders"

import ParalaxBg from require "background"

paused = false

local *

class Transport extends Box
  touching_player: 0
  is_transport: true

  message: "Press 'C' to exit"

  is_active: =>
    do return true
    @touching_player > 0

  enter: (world) =>
    error "replace me"

  update: (dt, world) =>
    if @touching_player > 0
      @touching_player -= 1

    if @touching_player == 0 and @message_box
      @message_box\hide!
      @message_box = nil

    true

  take_hit: (player, world) =>
    @touching_player = 2

    unless @message_box
      @message_box = MessageBox @message
      world.hud\show_message_box @message_box

  draw: =>
    Box.outline @

class World
  gravity_mag: 130
  spawn_x: 300
  spawn_y: 300

  new: (@game) =>
    @player = @game.player

    @viewport = EffectViewport scale: GAME_CONFIG.scale
    @entities = DrawList!
    @particles = DrawList!

    @player.x, @player.y = @spawn_x, @spawn_y
    @entities\add @player

    -- @entities\add Guppy 100, 100
    -- @entities\add Shark 160, 120
    -- @entities\add Jelly 120, 180
    @entities\add Snake 180, 180
    -- @entities\add Sardine 80, 200

    @entities\add @exit if @exit

    @viewport\center_on @player
    @hud = Hud!

    @collide = UniformGrid!

    @shader = Ripple @viewport

  mousepressed: (x,y) =>
    x, y = @viewport\unproject x, y
    for e in *@entities
      continue unless e.is_enemy
      e.facing = e.facing == "left" and "right" or "left"

  on_key: (key) =>
    if key == "return"
      paused = not paused

    if @exit\is_active! and CONTROLLER\is_down "cancel"
      @exit\enter world

  draw: =>
    @shader\render ->
      @viewport\apply!

      if @map
        @map\draw @viewport

      COLOR\pusha 64
      show_grid @viewport, 20, 20
      COLOR\pop!

      @entities\draw!
      @particles\draw!
      @viewport\outline!

      @viewport\pop!

    @viewport\apply!
    @hud\draw @viewport
    @viewport\pop!

  gravity: (vec, dt) =>
    do return
    return unless @gravity_pull
    vec\adjust unpack @gravity_pull * dt

  collides: (thing) =>
    if @map
      @map\collides(thing) or not @map_box\contains_box thing

  update: (dt) =>
    return if paused

    @_t or= 0
    @_t += dt
    @gravity_pull = Vec2d.from_angle(90 + math.sin(@_t * 2) * 7) * @gravity_mag

    @hud\update dt, @

    @viewport\update dt
    @viewport\center_on @player, @map_box, dt

    @entities\update dt, @
    @particles\update dt, @
    @collide\clear!

    for e in *@entities
      continue unless e.alive
      @collide\add e

    for e in *@collide\get_touching @player
      continue unless e.take_hit
      continue if e.stunned
      @player\take_hit e, @

-- wide open
class OceanMap extends Box
  x: 0
  y: 0

  w: 1000
  h: 300

  new: =>
    @bg = ParalaxBg!

  draw: (viewport) =>
    @bg\draw viewport, @

  update: (dt) =>

  collides: (thing) =>
    not @contains_box thing

class Ocean extends World
  new: (...) =>
    @map = OceanMap @
    @map_box = @map

    @exit = Transport 0, @map_box.h - 100, 100, 100
    @exit.enter = ->
      DISPATCHER\replace Home @game

    @spawn_x, @spawn_y = @exit\center!

    super ...

class Home extends World
  new: (...) =>
    @map = TileMap.from_tiled "maps/home", {
      object: (o) ->
        switch o.name
          when "spawn"
            @spawn_x = o.x
            @spawn_y = o.y
          when "exit"
            @exit = Transport o.x, o.y, o.width, o.height
            @exit.message = "Press 'C' to enter the sea"
            @exit.enter = ->
              DISPATCHER\replace Ocean @game
    }

    @map_box = @map\to_box!

    super ...

class Game
  @start: =>
    game = Game!
    Home game

  new: =>
    @player = Player 0, 0

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  fonts = {
    default: load_font "images/font1.png", [[ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~!"#$%&'()*+,-./0123456789:;<=>?]]
  }

  g.setFont fonts.default

  g.setBackgroundColor 12,14, 15

  export CONTROLLER = Controller GAME_CONFIG.keys

  export DISPATCHER = Dispatcher Game\start!
  DISPATCHER.default_transition = FadeTransition
  DISPATCHER\bind love

