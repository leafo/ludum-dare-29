{graphics: g} = love

import VList, HList, Label, Anchor from require "lovekit.ui"

class HBar extends Box
  p: 0.5
  w: 200
  h: 12
  padding: 2

  draw: =>
    @outline!
    COLOR\push {255, 100, 100, 128}
    full_width = @w - @padding * 2
    g.rectangle "fill", @x + @padding, @y + @padding,
      full_width * @p, @h - @padding * 2
    COLOR\pop!

class Hud
  new: =>
    @top_list = HList {
      yalign: "center"

      Label "Hello"
      HBar!
      Label "World"
    }

  draw: (v) =>
    g.push!
    g.translate v.x, v.y
    @top_list\draw!
    g.pop!

  update: (dt, world) =>
    @top_list\update dt

{ :Hud }
