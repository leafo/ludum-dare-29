
{graphics: g} = love

class Shader
  shader: => error "override me"

  new: =>
    @canvas = g.newCanvas!
    @canvas\setFilter "nearest", "nearest"
    @canvas\setWrap "repeat", "repeat"

    @shader = g.newShader @shader!

  render: (fn) =>
    old_canvas = g.getCanvas!

    g.setCanvas @canvas
    @canvas\clear 0,0,0,0

    fn!

    if old_canvas
      g.setCanvas old_canvas
    else
      g.setCanvas!

    g.setBlendMode "premultiplied"
    g.setShader @shader unless @disabled
    g.draw @canvas, 0,0
    g.setShader!
    g.setBlendMode "alpha"

class Ripple extends Shader
  shader: -> [[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      vec4 texcolor = Texel(texture, texture_coords);
      texcolor.r = 0;
      return texcolor * color;
    }
  ]]

{ :Ripple }
