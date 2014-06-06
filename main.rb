# -*- coding: utf-8 -*-
require_relative 'main_window'

MS_PER_UPDATE = 1 / 60.0
# MS_PER_UPDATE = 1 / 6.0

def main_loop(app)
  previous = Time.now
  lag = 0.0
  dirty = false

  loop do
    if Gtk.events_pending?
      Gtk.main_iteration
    end
    break if app.finished?

    current = Time.now
    lag += current - previous
    previous = current

    # 遅れを取り戻す。
    while lag >= MS_PER_UPDATE
      app.update
      dirty = true
      p :update if $DEBUG
      lag -= MS_PER_UPDATE
    end

    # 状態が変化していたら再描画する。
    # 変化していなかったら多少 sleep して CPU を開放する。
    if dirty
      p :draw if $DEBUG
      app.draw
      dirty = false
    else
      sleep(MS_PER_UPDATE / 3.0)
      next
    end
  end
end

# srand 1024
main_loop MainWindow.new.show_all
