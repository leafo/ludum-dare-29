{graphics: g} = love

import VList, HList, Label, Anchor from require "lovekit.ui"

class MessageBox
  padding: 5
  visible: true
  box_color: {0,0,0, 100}

  new: (@text) =>
    @alpha = 0
    @seq = Sequence ->
      tween @, 0.3, { alpha: 255 }
      @seq = nil

  draw: (viewport) =>
    left = viewport\left 10
    right = viewport\right 10
    bottom = viewport\bottom 10

    font = g.getFont!
    height = font\getHeight!
    width = right - left

    x = left
    y = bottom - height

    p = @padding

    COLOR\pusha @alpha
    g.push!
    g.translate x, y
    COLOR\push @box_color
    g.rectangle "fill", -p, -p, width + p * 2, height + p * 2
    COLOR\pop!
    g.print @text, 0,0
    g.pop!
    COLOR\pop!

  hide: =>
    return if @hiding or not @visible
    @hiding = true
    @seq = Sequence ->
      tween @, 0.2, { alpha: 0 }
      @hiding = false
      @visible = false

  update: (dt) =>
    @seq\update dt if @seq
    @visible

class HBar extends Box
  p: 0.5
  w: 100
  h: 12
  padding: 2

  draw: =>
    @outline!
    COLOR\push {255, 100, 100, 128}
    full_width = @w - @padding * 2
    g.rectangle "fill", @x + @padding, @y + @padding,
      full_width * @p, @h - @padding * 2
    COLOR\pop!


class Radar extends Box
  w: 50

  new: =>

  draw: =>
    Box.outline @

    g.push!
    g.translate @x, @y
    g.scale @w / @world.map_box.w, @h / @world.map_box.h
    g.setPointSize 4

    for e in *@world.entities
      continue unless e.alive
      continue unless e.center
      continue if e.is_misc

      pushed = if e.is_enemy
        COLOR\push 255,100,100, 128
        true
      elseif e.is_zone
        COLOR\push 100,255,100, 128
        true

      g.point e\center!

      COLOR\pop! if pushed

    g.pop!


  update: (dt, @world) =>
    r = @world.map_box.w / @world.map_box.h
    @h = @w / r
    true

class Hud
  margin: 10

  new: (world) =>
    @entities = DrawList!
    @display_score = world.game.score

    @health_bar = HBar!

    nice = (n) ->
      math.floor(n * 100) / 100

    @entities\add VList {
      x: @margin
      y: @margin

      HList {
        yalign: "center"
        Label "HP:"
        @health_bar

        Label -> "Score: #{math.floor @display_score}"
      }

      Label -> tostring love.timer.getFPS!
    }


    @radar = Anchor @margin, @margin, Radar!, "right", "top"
    @entities\add @radar


  has_message_box: =>
    return false unless @msg_box
    return @msg_box.visible

  show_message_box: (mbox) =>
    if @msg_box and @msg_box.visible
      @msg_box\hide!

    @msg_box = mbox
    @entities\add mbox

  draw: (v) =>
    return unless @world
    g.push!
    g.translate v.x, v.y
    @entities\draw v
    g.pop!

  update: (dt, @world) =>
    p = world.player
    @health_bar.p = smooth_approach @health_bar.p, p.health / p.__class.health, dt
    @radar.x = world.viewport.w - @margin

    @display_score = smooth_approach @display_score, @world.game.score, dt * 2

    @entities\update dt, world

{ :Hud, :MessageBox }
