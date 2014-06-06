# -*- coding: utf-8 -*-
class Keyboard
  include Gdk::Keyval

  INTERESTING_KEYS = [GDK_KEY_Up, GDK_KEY_Right, GDK_KEY_Down, GDK_KEY_Left, GDK_KEY_r]

  def initialize
    @key_state = Hash.new(false)
    @triggered = []
  end

  # トリガー状態をクリアする。
  def update
    @triggered.clear
  end

  def on_key_press(_self, e)
    if INTERESTING_KEYS.include? e.keyval
      if @key_state[e.keyval] == false
        @key_state[e.keyval] = true
        on_key_triggered(e.keyval)
      end
      true
    else
      false
    end
  end

  def on_key_release(_self, e)
    if INTERESTING_KEYS.include? e.keyval
      @key_state[e.keyval] = false
      true
    else
      false
    end
  end

  def on_key_triggered(keyval)
    case keyval
    when GDK_KEY_Up
      @triggered << :up
    when GDK_KEY_Right
      @triggered << :right
    when GDK_KEY_Down
      @triggered << :down
    when GDK_KEY_Left
      @triggered << :left
    when GDK_KEY_r
      @triggered << :reset
    end
  end

  def forget_key_state
    @key_state.clear
  end

  def triggered_keys
    @triggered
  end
end

