# -*- coding: utf-8 -*-
class Controller
  def initialize(world, widget)
    @world = world
    @clicked = false

    widget.events |= Gdk::Event::BUTTON_PRESS_MASK
    widget.signal_connect('button-press-event') do
      @clicked = true
    end
  end

  def update
    if @clicked
      @clicked = false
      @world.throw_in
    end
  end
end

require_relative 'wave'

require_relative 'frog'

class Pond
  NUM_FROGS = 3

  def initialize main_window
    @controller = Controller.new(self, main_window)
    @children = []
  end

  def create_frog
    pos = random_fringe_position
    direction = (Position[320,240] - pos).to_angle_radian + random_float(-0.75...0.75)
    Frog.new(self, pos, direction, 3)
  end

  def random_fringe_position
    random_y = rand < 0.5
    if random_y
      x = [0 - Frog::MARGIN/2, 640 + Frog::MARGIN/2].sample
      y = random_float(0...480)
      Position[x, y]
    else
      y = [0 - Frog::MARGIN/2, 640 + Frog::MARGIN/2].sample
      x = random_float(0...480)
      Position[x, y]
    end
  end

  # [first, last)
  def random_float(range)
    span = range.last - range.first
    range.first + rand * span
  end

  def throw_in
    x, y = [random_float(-100...740), random_float(-100...580)]

    spawn_epicenter(Position[x,y])
  end

  def spawn_epicenter(position)
    @children << Epicenter.new(position)
  end

  def update
    # カエルが居なければ産む
    @children << create_frog if @children.count { |x| x.is_a? Frog } < NUM_FROGS

    @controller.update
    @children.each do |child|
      child.update
    end
    @children.delete_if(&:dead?)
  end

  def draw cr
    @children.each do |child|
      child.draw(cr)
    end
  end
end
