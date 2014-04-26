{graphics: g} = love

import VList, HList, Label, Anchor from require "lovekit.ui"


class Hud
  new: =>
    @top_list = HList {
      yalign: "center"

      Label "Hello"
      Box 0, 0, 10, 10
      Label "World"
    }

  draw: (v) =>
    g.push!
    g.translate v.x, v.y
    @top_list\draw!
    g.pop!

  update: (dt) =>
    @top_list\update dt

{ :Hud }
