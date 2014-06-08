# rest -> kick -> straight -> lax -> reset
class Frog
  include Math

  def initialize(world, position = Position[0,0], direction = 0.5, speed)
    @world = world
    @position = position
    @direction = direction
    @kick_vector = Position[cos(direction), sin(direction)] * speed
    @vector = @kick_vector
    @state = :kick
    @count = 0
    @pixbuf_rest = Gdk::Pixbuf.new('1.png')
    @pixbuf_kick = Gdk::Pixbuf.new('2.png')
    @pixbuf_staight = Gdk::Pixbuf.new('3.png')
  end

  def update
    case @state
    when :rest
      if @count == 30
        @count = -1
        @state = :kick
      end
      @position += @vector
    when :kick
      if @count == 0
        @vector = @kick_vector / 2
      elsif @count == 10
        @count = -1
        @world.spawn_epicenter(@position)
        @vector = @kick_vector
        @state = :straight
      end
      @position += @vector
    when :straight
      if @vector.norm < 0.45
        @count = -1
        @state = :lax
      else
        @vector *= 0.99
      end
      @position += @vector
    when :lax
      if @vector.norm < 0.15
        @count = -1
        @state = :rest
      else
        @vector *= 0.99
      end
      @position += @vector
    end
    @count += 1
  end

  def draw cr
    # cr.set_source_color [0.2,1,1]
    # cr.circle(*@position, 10)
    # cr.fill

    deg = @direction * Math::PI / 180
    x, y = Position[pixbuf.width / 2, pixbuf.height / 2].rotate_deg(deg).to_a

    cr.save do
      cr.translate(@position.x , @position.y)
      cr.rotate(Math::PI / 2.0 + @direction)
      cr.translate(-x , -y)
      cr.set_source_pixbuf(pixbuf)
      cr.paint
    end
  end

  def pixbuf
    case @state
    when :rest
      @pixbuf_rest
    when :kick, :lax
      @pixbuf_kick
    when :straight
      @pixbuf_staight
    end
  end

  MARGIN = 200

  def dead?
    @position.x < 0 - MARGIN || @position.x > 640 + MARGIN ||
      @position.y < 0 - MARGIN || @position.y > 480 + MARGIN
  end
end
