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
    @health_bar = HBar!

    nice = (n) ->
      math.floor(n * 100) / 100

    @top_list = VList {
      x: 10
      y: 10

      HList {

        yalign: "center"
        Label "Fish"
        @health_bar
        Label ->
          tostring love.timer.getFPS!
      }

      Label ->
        return "" unless @world
        player = @world.player

        "Speed: #{nice player.vel\len!}, Vel: #{nice player.vel[1]},  #{nice player.vel[2]}"

      Label ->
        return "" unless @world
        player = @world.player
        return "" unless player.accel
        "Accel: #{nice player.accel[1]},  #{nice player.accel[2]}"


    }

  draw: (v) =>
    g.push!
    g.translate v.x, v.y
    @top_list\draw!
    g.pop!

  update: (dt, world) =>
    @world = world
    p = world.player
    @health_bar.p = smooth_approach @health_bar.p, p.health / p.max_health, dt

    @top_list\update dt

{ :Hud }
