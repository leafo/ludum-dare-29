
{graphics: g} = love

class FadeAway extends Sequence
  new: (@thing) =>
    super ->
      @alpha = 255
      @scale = 1
      tween @, 0.5, {
        alpha: 0
        scale: 3
      }

  draw: =>
    cx, cy = @thing\center!

    g.push!
    g.translate cx, cy
    COLOR\pusha @alpha
    g.scale @scale, @scale

    g.translate -cx, -cy
    @thing\draw!

    COLOR\pop!
    g.pop!
  
{ :FadeAway }
