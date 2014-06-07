# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'scene'
require_relative 'gtk_helper'
include Gtk

# Scene を持つ。Scene クラスはこのウィンドウに Cairo context を使って描
# 画する。
class MainWindow < Gtk::Window
  include GtkHelper

  def initialize
    super

    @finished = false
    set_title '偽んよんじゅうはち'

    signal_connect 'destroy' do
      @finished = true
    end

    init_ui

    set_window_position :center
  end

  def init_ui
    create(VBox) do |vbox|
      # vbox.pack_start(create_button_box, false)
      frame = AspectFrame.new(nil,	# no label
                              0.5, 0.5,	# center
                              -1, true) # infer aspect ratio from child
      frame.shadow_type = SHADOW_NONE
      @game_view = GameView.new
      frame.add @game_view
      vbox.pack_start(frame, true)
      add vbox
    end

    @game_view.grab_focus
  end

  def create_button_box
    create(HButtonBox,
           layout_style: ButtonBox::Style::START,
           border_width: 5) do |box|
      # button = create(Button, 'Reset')
      # box.pack_start(button)
    end
  end

  def finished?
    @finished
  end

  def invalidate
    window.invalidate(window.clip_region, true)
    window.process_updates(true)
  end

  def update
    @game_view.update
  end

  def draw
    invalidate
  end
end

class GameView < Gtk::DrawingArea
  def initialize
    super

    self.flags |= Widget::CAN_FOCUS

    set_size_request 640, 480
    init_ui

    self.events |= Gdk::Event::BUTTON_PRESS_MASK
    signal_connect('button-press-event') do
      if !focus?
        grab_focus
        true
      else
        false
      end
    end
  end

  def init_ui
    @scene = Scene.new(self)

    signal_connect('expose-event') do
      redraw
      true
    end
    @old_size = size
    signal_connect('configure-event') do |_, e|
      self.allocation.height = 480 * (e.width.to_f / 640)

      if [e.width, e.height] != @old_size
        redraw
        @old_size = size
      end
      true
    end
  end

  def size
    [allocation.width, allocation.height]
  end

  def zoom_ratio width, height
    [width.to_f / 640, height.to_f / 480]
  end

  def redraw
    cr = window.create_cairo_context
    vratio, hratio = zoom_ratio(*size)
    cr.scale(vratio, hratio)
    @scene.draw(cr)

    draw_veil(cr) unless focus?

    cr.destroy
  end

  def draw_veil(cr)
    cr.set_source_rgba(1,1,1, 0.5)
    cr.rectangle(0, 0, 640, 480)
    cr.fill
  end

  def update
    @scene.update
  end
end
