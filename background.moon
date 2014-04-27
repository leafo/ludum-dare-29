{graphics: g} = love

class ParalaxBg
  layers: 4
  speed: 1
  lazy sprite: -> imgfy "images/ground.png"

  new: (@viewport) =>
    @sprite\set_wrap "repeat", "clamp"

    @base_offsets = setmetatable {}, __index: (key) =>
      r = rand 0, 100
      @[key] = r
      r

  update: (dt) =>

  draw: =>
    w,h = @sprite\width!, @sprite\height!
    vw = @viewport.w

    for l=@layers,1,-1
      t = (@layers - (l - 1)) / @layers

      COLOR\push { t * 255, t * 255, t * 255 }

      scale = math.sqrt t
      real_w = w * scale

      times = math.floor(vw / real_w) + 2
      q = g.newQuad 0, 0, w * times, h, w, h

      g.push!
      g.translate @viewport.x, @viewport.y + @viewport.h
      
      px = -(l - 1) / @layers + 1

      g.translate -((@base_offsets[l] + @viewport.x) * px % real_w), (l - 1) * -10

      g.scale scale, scale

      @sprite\draw q, 0, -h
      g.pop!

      COLOR\pop!

{ :ParalaxBg }
