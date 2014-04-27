

import Guppy, Shark, Jelly, Snake, Sardine from require "enemy"

class Spawner extends Box
  radius: 40

  new: (@world) =>
    @area = world.map_box\shrink @radius

  position: =>
    with spawn_area = Box 0,0, @radius, @radius
      spawn_area\move_center @area\random_point!

  spawn: (num=1) =>
    spawn_area = @position!
    while spawn_area\touches_box @world.exit
      spawn_area = @position!

    for i=1,num
      @world.entities\add @create_enemy spawn_area\random_point!

  create_enemy: (x, y) =>
    error "override create_enemy #{@@.__name}"

class SardineSpawner extends Spawner
  create_enemy: (x,y) =>
    print "Creating sardine..."
    Sardine x, y

{ :Spawner, :SardineSpawner }
