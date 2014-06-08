class Wave
  def initialize pos, strength, speed
    @position = pos
    @speed = speed
    @tick = 0
    @strength = strength
  end

  def update
    @strength *= 0.985
    @tick += 1
  end

  def draw cr
    cr.set_source_color([1,1,1] + [0.025 * @strength])
    cr.set_line_width 15
    cr.circle(*@position, @speed / 60.0 * @tick)
    cr.stroke

    cr.set_source_color([0,0,0] + [0.025 * @strength])
    cr.set_line_width 15
    cr.circle(*@position, 15 + @speed / 60.0 * @tick)
    cr.stroke
  end

  def dead?
    @tick / 60.0 * @speed > 500
  end
end

class Epicenter
  def initialize pos, frequency = 3
    @position = pos
    @frequency = frequency
    @tick = 0
    @waves = []
    @strength = 1.0
  end

  def draw cr
    @waves.each do |wave|
      wave.draw(cr)
    end
  end

  def update
    if fertile? && @tick % (60 / @frequency) == 0
      @waves << Wave.new(@position, @strength, 100)
      @waves << Wave.new(@position + Position[-20,-20], @strength, 100)
      @strength *= 0.75
    end

    @waves.each(&:update)

    dead = @waves.select(&:dead?)
    @waves -= dead

    @tick += 1
  end

  def fertile?
    @strength >= 0.001
  end

  def dead?
    !fertile? && @waves.all?(&:dead?)
  end
end

