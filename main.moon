require "lovekit.all"

{graphics: g} = love

class Enemy extends Entity
  is_enemy: true
  speed: 20
  w: 40
  h: 20

  facing: "left"

  new: (...) =>
    super ...
    @accel = Vec2d!
    @seqs = DrawList!

  take_hit: (p, world) =>
    return if @stunned
    power = 5000

    world.viewport\shake!
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

    true

  draw: =>
    color = if @stunned
      {255,200,200}
    else
      {255,255,255}

    super color

class Player extends Entity
  is_player: true
  speed: 20
  max_speed: 100
  facing: "right"

  w: 40
  h: 20

  new: (...) =>
    super ...
    @seqs = DrawList!

  looking_at: (viewport) =>
    cx, cy = @center!
    switch @facing
      when "left"
        cx -= viewport.w / 10
      when "right"
        cx += viewport.w / 10

    cx, cy

  attack: (world) =>
    return if @stunned
    return if @attacking or @attacking_cooloff
    attack_speed = 300

    @attacking = @seqs\add Sequence ->
      start = love.timer.getTime!
      @vel[1] = 0

      force = attack_speed
      force = -force if @facing == "left"
      @attack_accel = Vec2d force, 0

      tween @attack_accel, 0.15, { 0, 0 }, lerp
      tween @attack_accel, 0.05, { -force/2, 0 }, lerp

      @attacking = false
      @attacking_cooloff = true
      wait 0.5
      @attacking_cooloff = false

  update: (dt, world) =>
    @seqs\update dt, world

    @accel = CONTROLLER\movement_vector @speed
    decel = @speed / 10

    if @attacking
      @accel[1] = @attack_accel[1]
    else
      if @accel[1] != 0
        @facing = @accel[1] > 0 and "right" or "left"

    if @stunned
      @accel[1], @accel[2] = unpack @stun_accel

    if @accel[1] == 0
      -- not moving in x, shrink it
      @vel[1] = dampen @vel[1], decel

    if @accel[2] == 0
      @vel[2] = dampen @vel[2], decel

    -- apply the ocean
    if @accel\is_zero!
      world\gravity @vel, dt

    @vel\adjust unpack @accel * dt * @speed
    @vel\cap @max_speed unless @attacking

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, world

    if cx
      @vel[1] = 0

    if cy
      @vel[2] = -@vel[2] / 2

    true

  draw: =>
    super!
    color = if @attacking
      {255,0, 0, 128}
    elseif @stunned
      {255,0, 255, 128}
    else
      {0,255, 0, 128}

    COLOR\push color
    size = 10
    y = @y + (@h - size) / 2

    if @facing == "right"
      g.rectangle "fill", @x + @w - size, y, size, size
    else
      g.rectangle "fill", @x, y, 10, 10

    COLOR\pop!

  take_hit: (enemy, world) =>
    if @attacking
      enemy\take_hit @, world
      return

    return if @stunned
    knockback = 400
    world.viewport\shake nil, nil, 2

    @stunned = @seqs\add Sequence ->
      dir = (Vec2d(@center!) - Vec2d(enemy\center!))\normalized!
      @stun_accel = dir * knockback
      wait 0.075
      @stunned = false

class Ocean
  gravity_mag: 130

  new: =>
    @viewport = EffectViewport scale: GAME_CONFIG.scale
    @entities = DrawList!

    @bounds = Box 0,0, 1000, 1000

    @player = Player 20, 20
    @entities\add @player
    @entities\add Enemy 100, 100

    @viewport\center_on @player

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

    @viewport\update dt
    @viewport\center_on @player, nil, dt

    @entities\update dt, @
    @collide\clear!

    for e in *@entities
      continue unless e.is_enemy
      continue if e.stunned

      if @player\touches_box e
        @player\take_hit e, @


love.load = ->
  export CONTROLLER = Controller GAME_CONFIG.keys
  export DISPATCHER = Dispatcher Ocean!

  DISPATCHER\bind love

