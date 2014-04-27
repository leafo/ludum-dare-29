require "lovekit.all"
require "lovekit.reloader"

{graphics: g} = love

import Hud from require "hud"
import Player from require "player"
import Guppy, Shark, Jelly, Snake, Sardine from require "enemy"

import Ripple from require "shaders"

import ParalaxBg from require "background"

paused = false

-- wide open
class OceanMap extends Box
  x: 0
  y: 0

  w: 1000
  h: 400

  new: (world) =>
    @bg = ParalaxBg!

  draw: (viewport) =>
    @bg\draw viewport

  update: (dt) =>

  collides: (thing) =>
    not @contains_box thing

class Ocean
  gravity_mag: 130
  spawn_x: 300
  spawn_y: 300

  new: =>
    @viewport = EffectViewport scale: GAME_CONFIG.scale
    @entities = DrawList!
    @particles = DrawList!

    @player = Player @spawn_x, @spawn_y
    @entities\add @player

    @entities\add Guppy 100, 100
    @entities\add Shark 160, 120
    @entities\add Jelly 120, 180
    @entities\add Snake 180, 180
    @entities\add Sardine 80, 200

    @viewport\center_on @player
    @hud = Hud!

    @collide = UniformGrid!

    @shader = Ripple @viewport

    unless @map
      @map = OceanMap @
      @map_box = @map

  mousepressed: (x,y) =>
    x, y = @viewport\unproject x, y
    for e in *@entities
      continue unless e.is_enemy
      e.facing = e.facing == "left" and "right" or "left"

  on_key: (key) =>
    if key == "return"
      paused = not paused

  draw: =>
    @shader\render ->
      @viewport\apply!

      if @map
        @map\draw @viewport

      COLOR\pusha 128
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
      @map\collides thing

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
      continue unless e.is_enemy
      continue if e.stunned
      @player\take_hit e, @

class Home extends Ocean
  new: =>
    @map = TileMap.from_tiled "maps/home", {
      object: (o) ->
        switch o.name
          when "spawn"
            @spawn_x = o.x
            @spawn_y = o.y
    }

    @map_box = @map\to_box!

    super!

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  fonts = {
    default: load_font "images/font1.png", [[ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~!"#$%&'()*+,-./0123456789:;<=>?]]
  }

  g.setFont fonts.default

  g.setBackgroundColor 15,17, 18

  export CONTROLLER = Controller GAME_CONFIG.keys
  export DISPATCHER = Dispatcher Home!

  DISPATCHER\bind love

