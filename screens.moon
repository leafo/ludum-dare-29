
import Ripple from require "shaders"
import Anchor, RevealLabel from require "lovekit.ui"

class Transition extends FadeTransition
  time: 1.5
  color: {10, 10, 10}

class Title
  lazy background: -> imgfy "images/title.png"

  new: (@start) =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @shader = Ripple @viewport
    @entities = DrawList!

    l = RevealLabel "Press 'X' to begin"
    l.rate = 0.1

    cx, cy = @viewport\center!
    @entities\add Anchor cx, cy + 70, l, "center", "center"

  on_show: =>
    unless AUDIO.current_music == "title"
      AUDIO\play_music "title"
      AUDIO.music\setVolume 0.25

  draw: =>
    @shader\render ->
      @viewport\apply!
      @background\draw 0, 0
      @entities\draw @viewport
      @viewport\pop!

  update: (dt) =>
    @entities\update dt

  on_key: =>
    if CONTROLLER\is_down "confirm"
      AUDIO\play "start"
      DISPATCHER\replace @start, Transition


class GameOver
  new: (game) =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @shader = Ripple @viewport
    @entities = DrawList!

    msg = if game\beat_game!
      "You're conquered the ocean"
    else
      "You have become fish fodder"

    l = RevealLabel "#{msg}\nPress 'X' to return to title\nThanks for playing!\nYour score: #{game.score}"

    cx, cy = @viewport\center!
    @entities\add Anchor cx, cy - 20, l, "center", "center"

  draw: =>
    @shader\render ->
      @viewport\apply!
      @entities\draw @viewport
      @viewport\pop!

  update: (dt) =>
    @entities\update dt

  on_show: =>
    if AUDIO.music
      AUDIO.music\stop!

  on_key: =>
    import Game from require "main"

    if CONTROLLER\is_down "confirm"
      DISPATCHER\replace Title Game\start!

{ :Title, :GameOver }
