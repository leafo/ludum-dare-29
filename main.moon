require "lovekit.all"

{graphics: g} = love

import Hud from require "hud"
import BubbleEmitter from require "particles"
import Player from require "player"

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

class Ocean
  gravity_mag: 130

  new: =>
    @viewport = EffectViewport scale: GAME_CONFIG.scale
    @entities = DrawList!
    @particles = DrawList!

    @bounds = Box 0,0, 1000, 500

    @player = Player 20, 20
    @entities\add @player
    @entities\add Enemy 100, 100

    @viewport\center_on @player
    @hud = Hud!

    @collide = UniformGrid!

  on_key: =>
    if CONTROLLER\is_down "attack"
      @player\attack @

  draw: =>
    @viewport\apply!
    COLOR\pusha 128
    show_grid @viewport, 20, 20
    COLOR\pop!

    @bounds\draw {255,255,255,20}

    @entities\draw!
    @particles\draw!

    @hud\draw @viewport

    @viewport\pop!

  gravity: (vec, dt) =>
    return unless @gravity_pull
    vec\adjust unpack @gravity_pull * dt

  collides: (thing) =>
    not @bounds\contains_box thing

  update: (dt) =>
    @_t or= 0
    @_t += dt
    @gravity_pull = Vec2d.from_angle(90 + math.sin(@_t * 2) * 7) * @gravity_mag

    @hud\update dt, @

    @viewport\update dt
    @viewport\center_on @player, nil, dt

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
  export DISPATCHER = Dispatcher Ocean!

  DISPATCHER\bind love

