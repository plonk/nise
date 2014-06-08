class Rectangle
  attr_reader :x, :y, :width, :height

  def initialize(x, y, width, height)
    @x = x
    @y = y
    @width = width
    @height = height
  end
end

require 'matrix'

module Trig
  include Math

  def deg_to_rad(deg)
    deg.fdiv(180.0) * PI
  end
  module_function :deg_to_rad

  def rad_to_deg(rad)
    (rad * 180).fdiv(PI)
  end
  module_function :rad_to_deg
end

class Position
  include Math
  include Trig

  attr_accessor :x, :y

  def initialize(x, y)
    @x = x; @y = y
  end

  ZERO = Position.new(0,0)

  def +(other)
    Position.new(x + other.x, y + other.y)
  end

  def -(other)
    Position.new(x - other.x, y - other.y)
  end

  def *(scalar)
    Position.new(x * scalar, y * scalar)
  end

  def /(scalar)
    Position.new(x / scalar, y / scalar)
  end

  def lerp(other, factor)
    fail RangeError unless factor >= 0 && factor <= 1

    self * (1-factor) + other * factor
  end

  def within?(rectangle)
    @x.between?(rectangle.x, rectangle.x + rectangle.width - 1) &&
      @y.between?(rectangle.y, rectangle.y + rectangle.height - 1)
  end

  def zero?
    @x == 0 && @y == 0
  end

  def to_a
    [@x, @y]
  end

  def rotate_deg(theta)
    rotate_radian(deg_to_rad(theta))
  end

  def rotate_radian(theta)
    vec = rotation_matrix(theta) * Vector[@x, @y]
    Position.new(*vec)
  end

  def rotation_matrix(theta)
    Matrix[[cos(theta), -sin(theta)], [sin(theta), cos(theta)]]
  end

  def self.[](x, y)
    Position.new(x,y)
  end

  def to_angle_deg
    rad_to_deg(to_angle_radian)
  end

  def to_angle_radian
    atan2(@y, @x)
  end

  def normalize
    self / sqrt(@x ** 2 + @y ** 2)
  end

  def norm
    sqrt(@x ** 2 + @y ** 2)
  end
end
