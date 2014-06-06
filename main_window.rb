# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'scene'
# require_relative 'keyboard'
include Gtk

class MainWindow < Gtk::Window
  def initialize
    super

    @finished = false
    set_title '偽んよんじゅうはち'

    signal_connect 'destroy' do
      @finished = true
    end

    init_ui

    set_default_size 640, 480
    set_window_position :center
    show_all
  end

  def finished?
    @finished or @scene.finished?
  end

  def invalidate
    window.invalidate(window.clip_region, true)
    window.process_updates(true)
  end

  def init_ui
    @scene = Scene.new(self)

    signal_connect('expose-event') do
      redraw
      true
    end
    @old_size = size
    signal_connect('configure-event') do |_, e|
      if [e.width, e.height] != @old_size
        redraw
        @old_size = size
      end
      true
    end
  end

  def redraw
    cr = window.create_cairo_context
    w, h = size
    cr.scale(w.fdiv(640), h.fdiv(480))
    @scene.draw(cr)
    cr.destroy
  end

  def update
    @scene.update
  end

  def draw
    invalidate
  end
end
