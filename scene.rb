# -*- coding: utf-8 -*-
class Position
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x; @y = y
  end

  def +(other)
    Position.new(x + other.x, y + other.y)
  end

  def *(scalar)
    Position.new(x * scalar, y * scalar)
  end

  def lerp(other, factor)
    fail RangeError unless factor >= 0 && factor <= 1

    self * (1-factor) + other * factor
  end
end

class Tile
  attr_accessor :position, :previous_position, :number, :merged_from

  def initialize(position, number, merged_from = [])
    @position = position
    @number = number
    @merged_from = merged_from
  end

  def clear_merger_info
    @merged_from = []
  end

  def new?
    previous_position.nil? && merged_from == []
  end

  def merged?
    merged_from != []
  end

  def save_position
    @previous_position = position
  end
end

class Grid
  # 初期グリッドを用意する。ランダムな位置に2つタイルがある
  def self.starting_grid
    grid = Grid.new
    2.times do
      position = grid.random_available_cell
      tile = Tile.new(position, [2,2,2,2,2,2,2,2,2,4].sample)
      grid[position] = tile
    end
    grid
  end

  def self.testing_grid
    grid = Grid.new
    num = 2
    for y in 0...4
      for x in 0...4
        pos = Position.new(x, y)
        tile = Tile.new(pos, num)
        grid[pos] = tile
        num *= 2
      end
    end
    grid
  end

  def initialize
    @table = Array.new(4) { Array.new(4) }
  end

  def [](position)
    @table[position.y][position.x] if within_bounds? position
  end

  def []=(position, tile)
    @table[position.y][position.x] = tile if within_bounds? position
  end

  def delete(tile)
    self[tile.position] = nil
  end

  def move_tile(tile, dest)
    fail unless self[tile.position] == tile

    self[tile.position] = nil
    tile.position = dest
    self[dest] = tile
  end

  def all_tiles
    @table.flatten.compact
  end

  def within_bounds? position
    position.x >= 0 && position.x < 4 &&
    position.y >= 0 && position.y < 4
  end

  def random_available_cell
    available_cells.sample
  end

  def available_cells
    (0...4).flat_map do |x|
      (0...4).flat_map do |y|
        if @table[y][x].nil?
          [ Position.new(x, y) ]
        else
          []
        end
      end
    end
  end

  def occupied? cell
    !@table[cell.y][cell.x].nil?
  end

  def available? cell
    !occupied? cell
  end
end

class Graphics
  attr_accessor :context

  TILE_WIDTH = 100
  TILE_HEIGHT = 90
  LEFT_MARGIN = 90
  TOP_MARGIN = 30
  VSPACING = 20
  HSPACING = 20

  def translate(pos)
    Position.new(LEFT_MARGIN + (HSPACING + TILE_WIDTH) * pos.x + TILE_WIDTH/2,
                 TOP_MARGIN + (VSPACING + TILE_HEIGHT) * pos.y + TILE_HEIGHT/2)
  end

  def initialize
    @background_image = Cairo::ImageSurface.from_png('background1.png')
  end

  def draw_background
    @context.set_source(@background_image)
    @context.paint
  end

  def draw_board
    board_width = HSPACING * 5 + TILE_WIDTH * 4
    board_height = VSPACING * 5 + TILE_HEIGHT * 4
    pos = Position.new(LEFT_MARGIN + board_width/2 - HSPACING,
                       TOP_MARGIN + board_height/2 - VSPACING)
    draw_rectangle(pos,
                   board_width,
                   board_height,
                   [0]*3 + [0.5],
                   1.0) # zoom
  end

  def draw_tile coordinates, label, fg_color, bg_color, zoom_factor
    width, height = [TILE_WIDTH, TILE_HEIGHT]
    draw_shadow(coordinates, width, height, zoom_factor)
    draw_rectangle(coordinates, width, height, bg_color, zoom_factor)
    draw_label(coordinates, label, fg_color, zoom_factor)
  end

  def draw_shadow coordinates, width, height, zoom_factor
    shadow_offset = Position.new(3, 3)
    draw_rectangle(coordinates + shadow_offset, width, height, [0,0,0, 0.3], zoom_factor)
  end

  def fill_background color
    @context.rounded_rectangle(0, 0, 640, 480, 10)
    @context.set_source_color color
    @context.fill
  end

  def draw_rectangle(pos, width, height, color, zoom_factor)
    @context.rounded_rectangle(pos.x - (width/2 * zoom_factor),
                               pos.y - (height/2 * zoom_factor),
                               width * zoom_factor,
                               height * zoom_factor,
                               10)
    @context.set_source_color color
    @context.fill
  end

  def draw_label(pos, label, color, zoom_factor)
    @context.select_font_face('Arial Black',
                        Cairo::FONT_SLANT_NORMAL,
                        Cairo::FONT_WEIGHT_BOLD)
    @context.set_font_size(label_size(label) * zoom_factor)
    @context.set_source_rgb(*color)
    extents = @context.text_extents(label)
    @context.move_to(pos.x - extents.width / 2 - extents.x_bearing,
                     pos.y - extents.height / 2 - extents.y_bearing)
    @context.show_text(label)
  end

  def label_size label
    case label.size
    when 1..3
      40
    when 4
      35
    else
      28
    end
  end
end

require_relative 'keyboard'

class InputController
  def initialize widget
    @widget = widget
    @handlers = []
    @keyboard = Keyboard.new

    @widget.events |= Gdk::Event::KEY_PRESS_MASK | Gdk::Event::KEY_RELEASE_MASK
    @handlers << widget.signal_connect('key-press-event') do |*args|
      @keyboard.on_key_press(*args)
      true
    end

    @handlers << widget.signal_connect('key-release-event') do |*args|
      @keyboard.on_key_release(*args)
      true
    end

    @handlers << widget.signal_connect('focus-out-event') do
      @keyboard.forget_key_state
      true
    end
  end

  def command
    @keyboard.triggered_keys.first
  end

  def update
    @keyboard.update
  end

  def deinitialize
    @handlers.each do |id|
      @widget.signal_handler_disconnect(id)
    end
  end
end

# update メソッドは作らない
class Game
  attr_accessor :grid

  def initialize
    reset
  end

  def over?
    @over
  end

  def slide direction
    grid.all_tiles.each do |tile|
      tile.save_position
      tile.clear_merger_info
    end
    vector = to_vector(direction)
    changed = false

    traverse(direction) do |pos|
      next unless tile = grid[pos]

      dest = farthest(tile, vector)

      if (other = grid[dest + vector]) && other.number == tile.number && !other.merged?
        # マージする
        grid.delete(tile)
        tile.position = dest + vector
        grid.delete(other)
        grid[dest + vector] = Tile.new(dest + vector, tile.number * 2, [tile, other])
      else
        next if dest == tile.position
        # 画面端か、マージできないタイルに隣接
        grid.move_tile(tile, dest)
      end
      changed = true
    end

    if changed
      spawn_new_tile
    end

    decide_gameover
  end

  def decide_gameover
    @over = !moves_available?
  end

  def moves_available?
    !grid.available_cells.empty? || merger_possible?
  end

  # 空きセルは無いと過程してマージできるセルがあるか判定する
  def merger_possible?
    for y in 0...4
      for x in 0...4
        this = grid[Position.new(x, y)]
        if grid.within_bounds?(Position.new(x+1, y)) && right = grid[Position.new(x+1, y)]
          return true if right && right.number == this.number
        end
        if grid.within_bounds?(Position.new(x, y+1)) && below = grid[Position.new(x, y+1)]
          return true if below && below.number == this.number
        end
      end
    end
    return false
  end

  def spawn_new_tile
    position = grid.random_available_cell
    grid[position]= Tile.new(position, [2,2,2,2,2,2,2,2,2,4].sample)
  end

  def farthest(tile, vector)
    pos = tile.position
    loop do
      if !grid.within_bounds?(pos + vector)
        return pos
      elsif grid[pos + vector]
        return pos
      end
      pos += vector
    end
  end

  def to_vector direction
    case direction
    when :left  then Position.new(-1,  0)
    when :up    then Position.new( 0, -1)
    when :down  then Position.new( 0, +1)
    when :right then Position.new(+1,  0)
    end
  end

  def traverse(direction)
    xs = direction == :right ? 3.downto(0) : 0.upto(3)
    ys = direction == :down  ? 3.downto(0) : 0.upto(3)

    ys.each do |y|
      xs.each do |x|
        yield(Position.new(x, y))
      end
    end
  end

  def reset
    if $DEBUG
      @grid = Grid.testing_grid
    else
      @grid = Grid.starting_grid
    end
    decide_gameover
  end
end

class Scene
  def initialize main_window
    @input = InputController.new(main_window)
    @graphics = Graphics.new

    @game = Game.new

    @state = :animation
    @animation_frame = 0
  end

  def update
    case @state
    when :idle
      idle_update
      @input.update
    when :animation
      animation_update
    when :gameover
      gameover_update
      @input.update
    end
  end

  def gameover_update
    if @input.command == :reset
      @game.reset
      @state = :animation
      @animation_frame = 0
    end
  end

  def idle_update
    if @game.over?
      @state = :gameover
      return
    end

    return unless @input.command

    case @input.command
    when :left
      @game.slide :left
    when :right
      @game.slide :right
    when :up
      @game.slide :up
    when :down
      @game.slide :down
    when :reset
      @game.reset
    end
    @state = :animation
    @animation_frame = 0
  end

  def animation_update
    @animation_frame += 1
    if @animation_frame == 20
      @state = :idle
    end
  end

  def draw cr
    @graphics.context = cr
    @graphics.draw_background
    @graphics.draw_board
    case @state
    when :animation
      animation_draw
    when :idle
      idle_draw
    when :gameover
      gameover_draw
    end
    @graphics.context = nil
  end

  def animation_draw
    case @animation_frame
    when 0...10
      @game.grid.all_tiles.each do |tile|
        if tile.previous_position
          old_coords = @graphics.translate(tile.previous_position)
          new_coords = @graphics.translate(tile.position)
          coords = old_coords.lerp(new_coords, @animation_frame / 10.0)

          @graphics.draw_tile(coords,
                              tile.number.to_s,
                              label_color(tile.number),
                              tile_color(tile.number),
                              1)
        else
          # マージされたタイルの過去のすがたを描画する
          tile.merged_from.each do |half|
            if half.previous_position
              old_coords = @graphics.translate(half.previous_position)
            else
              old_coords = @graphics.translate(half.position)
            end
            new_coords = @graphics.translate(half.position)
            coords = old_coords.lerp(new_coords, @animation_frame / 10.0)

            @graphics.draw_tile(coords,
                                half.number.to_s,
                                label_color(half.number),
                                tile_color(half.number),
                                1)
          end
        end
      end
    when 10...20
      @game.grid.all_tiles.each do |tile|
        if tile.new?
          x = (@animation_frame - 10) / 10.0
          scale = 0.5 + x * 0.5
        elsif tile.merged?
          # 前半大きくなって、後半元の大きさにもどってゆく
          x = (@animation_frame - 10) / 10.0
          if x < 0.5
            scale = 1.0 + (x * 0.3)
          else
            scale = 1.0 + (1.0 - x) * 0.3
          end
        else
          scale = 1
        end

        @graphics.draw_tile(@graphics.translate(tile.position),
                            tile.number.to_s,
                            label_color(tile.number),
                            tile_color(tile.number),
                            scale)
      end
    end
  end

  def idle_draw
    @game.grid.all_tiles.each do |tile|
      number = tile.number.to_s
      color = tile_color(tile.number)
      @graphics.draw_tile(@graphics.translate(tile.position),
                          number,
                          label_color(tile.number),
                          color,
                          1.0)
    end
  end

  def gameover_draw
    @graphics.fill_background([0.6, 0.0, 0.0])
    idle_draw
  end

  def tile_color number
    case number
    when 2
      color('#9c9cf7') # blue
    when 4
      color('#f79cca') # red
    when 8
      color('#9cf7c9') # green
    when 16
      color('#f7f79c') # yellow
    when 32
      color('#005bed') # blue
    when 64
      color('#ed0e81') # magenta
    when 128
      color('#0af580') # green
    when 256
      color('#e03131') # dark red
    when 512
      color('#b105f5') # purple
    when 1024
      color('#0ce4f0') # cyan
    when 2048
      color('#ffdd00') # yellow
    when 4096
      color('#19ffbe') # emerald
    else
      BLACK
    end
  end

  def label_color number
    case number
    when 32, 64, 256, 512, 8192..Float::INFINITY
      [0.9, 0.9, 0.9]
    else
      [0.2, 0.2, 0.2]
    end
  end

  def color str
    if str =~ /^\#(..)(..)(..)$/
      [$1, $2, $3].map do |digits|
        digits.to_i(16) / 255.0
      end
    else
      MAGENTA
    end
  end

  MAGENTA = [1.0, 0, 1.0]
  BLACK = [0, 0, 0]
  BLUE = [0.20, 0.23, 0.90]
  RED = [0.90, 0.25, 0.25]
  GREEN = [0.20, 0.80, 0.20]
  WHITE = [1, 1, 1]

  def finished?
    false
  end

  def deinitialize
  end
end
