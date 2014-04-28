require "lovekit.all"
-- require "lovekit.reloader"

{graphics: g} = love

import Hud, MessageBox from require "hud"
import Player from require "player"
import Guppy, Shark, Jelly, Snake, Sardine from require "enemy"

import Ripple from require "shaders"

import ParalaxBg from require "background"

paused = false

import RevealLabel, Anchor from require "lovekit.ui"

local *

class Intro extends Sequence
  new: (@world, callback) =>
    @entities = DrawList!

    anchor = (label) ->
      cx, cy = @world.viewport\center!
      label.rate = 0.05
      Anchor cx, cy, label, "center", "center"

    intro = {
      "There's something foul\n      in the ocean\n(press 'X' to continue)"
      "The duty of a fish calls..."
      "Arrows move, 'X' attacks\nDouble tap to boost"
      "Go forth and rid the sea of evil"
    }

    super ->
      @world.hud_alpha = 0
      @world.seqs\add AUDIO\fade_music 0.75

      wait 2.0
      AUDIO\play "intro_explosion"
      @world.viewport\shake 2.0

      wait 2.0

      local current
      for msg in *intro
        if current
          @entities\remove current
          current = nil

        await (fn) ->
          current = anchor RevealLabel msg, 10, 10, fn
          @entities\add current

        wait_for_key unpack GAME_CONFIG.keys.confirm

      @world.seqs\add Sequence ->
        tween @world, 1.0, hud_alpha: 255

      callback!

  update: (dt) =>
    if CONTROLLER\is_down "cancel"
      dt *= 2

    @entities\update dt
    super dt

  draw: (...) =>
    @entities\draw ...

class Zone extends Box
  is_zone: true

  touching_player: 0

  activate: (world) =>
    error "replace me"

  is_ready: =>
    @touching_player > 0

  update: (dt, world) =>
    if @touching_player > 0
      @touching_player -= 1

    if @touching_player == 0 and @message_box
      @message_box\hide!
      @message_box = nil

    true

  take_hit: (player, world) =>
    @touching_player = 2

    if @is_ready! and @message and not @message_box
      @message_box = MessageBox @message
      world.hud\show_message_box @message_box

  draw: =>
    -- Box.outline @

class Transport extends Zone
  message: "Press 'C' to exit"

class RestZone extends Zone
  is_misc: true
  message: "Press 'C' to rest"
  new: (@world, ...) =>
    super ...

  is_ready: =>
    super! and @world.can_rest

class World
  gravity_mag: 130
  spawn_x: 300
  spawn_y: 300
  hud_alpha: 255
  overlay_alpha: 0

  new: (@game) =>
    @player = @game.player
    @player.vel[1] = 0
    @player.vel[2] = 0

    @viewport = EffectViewport scale: GAME_CONFIG.scale
    @entities = DrawList!
    @particles = DrawList!
    @seqs = DrawList!

    @set_player_pos!

    @entities\add @player
    @entities\add @exit if @exit
    @entities\add @rest if @rest

    @hud = Hud @

    @collide = UniformGrid!

    @shader = Ripple @viewport

  set_player_pos: (x=@spawn_x, y=@spawn_y) =>
    @player.x, @player.y = x, y
    @viewport\center_on @player

  on_show: =>
    return if @game.show_intro
    @start_music!

  start_music: =>
    unless AUDIO.current_music == "main"
      AUDIO\play_music "main"

  mousepressed: (x,y) =>
    x, y = @viewport\unproject x, y
    for e in *@entities
      continue unless e.is_enemy
      e.facing = e.facing == "left" and "right" or "left"

  on_key: (key) =>
    if key == "return"
      paused = not paused

    if CONTROLLER\is_down "cancel"
      if @exit\is_ready!
        @exit\activate @

      if @rest and @rest\is_ready!
        @rest\activate @

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

      if @overlay_alpha and @overlay_alpha > 0
        @viewport\apply!
        COLOR\push {0,0,0, @overlay_alpha}
        Box.draw @viewport
        COLOR\pop!
        @viewport\pop!

      @viewport\pop!

    @viewport\apply!

    COLOR\pusha @hud_alpha
    @hud\draw @viewport
    COLOR\pop!

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
    @seqs\update dt, @

    @collide\clear!

    for e in *@entities
      continue unless e.alive
      continue unless e.w -- is boxy
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


import
  SardineSpawner
  JellySpawner
  GuppySpawner
  SnakeSpawner
  SharkSpawner
  from require "spawners"

class Ocean extends World
  levels: {
    => -- 1
      SardineSpawner(@)\spawn 5
      SardineSpawner(@)\spawn 8

    => -- 2
      SardineSpawner(@)\spawn 8
      JellySpawner(@)\spawn 3
      JellySpawner(@)\spawn 3

    => -- 3
      JellySpawner(@)\spawn 3
      GuppySpawner(@)\spawn 2
      SnakeSpawner(@)\spawn 2

    => -- 4
      SharkSpawner(@)\spawn 1

      GuppySpawner(@)\spawn 1
      GuppySpawner(@)\spawn 1
      GuppySpawner(@)\spawn 1

      SnakeSpawner(@)\spawn 2
      SnakeSpawner(@)\spawn 2


    => -- 5
      SharkSpawner(@)\spawn 2
      SharkSpawner(@)\spawn 2

      GuppySpawner(@)\spawn 3
      GuppySpawner(@)\spawn 3

      SardineSpawner(@)\spawn 5
      SardineSpawner(@)\spawn 5
  }

  new: (...) =>
    @map = OceanMap @
    @map_box = @map

    @exit = Transport 0, @map_box.h - 100, 100, 100
    @exit.message = "Press 'C' to return to home"
    @exit.activate = ->
      @entities\remove @player
      home = Home @game
      home.can_rest = not @has_enemies!

      DISPATCHER\replace home
      home\set_player_pos home.exit\center!

    @spawn_x, @spawn_y = @exit\center!

    super ...

    if level = @levels[@game.current_level]
      level @

  on_show: (...) =>
    super ...
    if @game\beat_game!
      import GameOver from require "screens"
      DISPATCHER\replace GameOver @game

  has_enemies: =>
    has_enemies = false
    for e in *@entities
      if e.alive and e.is_enemy
        has_enemies = true
        break

    has_enemies

  update: (dt) =>
    has_enemies = @has_enemies!

    if not has_enemies and not @return_mb
      @return_mb = MessageBox "The ocean is calm"
      @hud\show_message_box @return_mb

    super dt


class Home extends World
  can_rest: false

  new: (...) =>
    @map = TileMap.from_tiled "maps/home", {
      object: (o) ->
        switch o.name
          when "spawn"
            @spawn_x = o.x
            @spawn_y = o.y
          when "rest"
            @rest = RestZone @, o.x, o.y, o.width, o.height
            @rest.activate = @\do_rest
          when "exit"
            @exit = Transport o.x, o.y, o.width, o.height
            @exit.message = "Press 'C' to enter the sea"
            @exit.activate = ->
              @entities\remove @player
              DISPATCHER\replace Ocean @game
    }

    @map_box = @map\to_box!

    super ...

    do return
    if @game.show_intro
      @player.locked = true
      @entities\add Intro @, ->
        @start_music!
        @player.locked = false

  do_rest: =>
    @can_rest = false

    @seqs\add Sequence ->
      @player.locked = true

      @hud\clear_message_box!
      tween @, 1.0, overlay_alpha: 255
      @player.health = @player.__class.health
      AUDIO\play "recover"
      wait 1.0
      tween @, 1.0, overlay_alpha: 0

      local current
      await (fn) ->
        label = with RevealLabel "The feral fish grow stronger", 10, 10, fn
          .rate = 0.05
        cx, cy = @viewport\center!
        current = Anchor cx, cy, label, "center", "center"

        @entities\add current

      wait_for_key unpack GAME_CONFIG.keys.confirm
      @entities\remove current
      @player.locked = false
      @game.current_level += 1

class Game
  current_level: 5
  show_intro: false -- true

  @start: =>
    game = Game!
    Home game

  beat_game: =>
    not Ocean.levels[@current_level]

  new: =>
    @score = 0
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

  import Title from require "screens"

  export AUDIO = Audio "sounds"
  AUDIO\preload {
    "bump_wall"
    "charge"
    "enemy_die"
    "hit1"
    "hit2"
    "recover"
    "start"
    "player_die"
    "boost"
    "intro_explosion"
  }

  AUDIO.play_music = =>
    @music = setmetatable {}, __index: -> ->

  export CONTROLLER = Controller GAME_CONFIG.keys
  export DISPATCHER = Dispatcher Title Game\start!

  DISPATCHER.default_transition = FadeTransition
  DISPATCHER\bind love

{ :Game, :Home, :Ocean }
