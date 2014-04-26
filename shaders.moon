
{graphics: g} = love

class Shader
  shader: => error "override me"

  new: (@viewport) =>
    @canvas = g.newCanvas!
    @canvas\setFilter "nearest", "nearest"
    @canvas\setWrap "repeat", "repeat"

    @shader = g.newShader @shader!

  send: =>

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
    @send!
    g.draw @canvas, 0,0
    g.setShader!
    g.setBlendMode "alpha"

class Ripple extends Shader
  send: =>
    @shader\send "pixel_ratio_x", 1/@viewport.w
    -- @shader\send "pixel_ratio_y", 1/@viewport.h
    @shader\send "time", love.timer.getTime!

  shader: -> [[
    #define M_PI 3.1415926535897932384626433832795

    extern number time;
    extern number pixel_ratio_x;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      number x = texture_coords.x + sin(texture_coords.x * 10 + time) * (pixel_ratio_x * 2) + sin(time + texture_coords.y * M_PI * 5) * (pixel_ratio_x / 2);
      number y = texture_coords.y;

      vec4 c = Texel(texture, vec2(x, y));
      c.r = abs(sin(time)) * c.r;
      return c * color;
    }
  ]]

{ :Ripple }
