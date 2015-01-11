class CookieNode < SKSpriteNode
  attr_accessor :normal_scale

  def self.init_with_image(image, scale, position)
    sprite = CookieNode.spriteNodeWithImageNamed(image)
    sprite.normal_scale = scale
    sprite.scale = scale
    sprite.position = position
    sprite
  end

  def pre_shuffle_setup
    xScale = 0.5
    yScale = 0.5
    alpha = 0
  end

  def animate_cookie_appear
    run_sequence do
      wait 0.25, 0.5
      group do
        fade_in 0.25
        scale_to normal_scale, 0.25
      end
    end
  end

  def animate_fall(position, duration, delay, sound)
    run_sequence do
      wait delay
      group do
        move_to(position, duration).ease_out
        other_action sound
      end
    end
  end

  def animate_new(position, duration, delay,  sound)
    alpha = 0
    wait delay
    group do
      fade_in 0.5
      move_to(position, duration).ease_out
      other_action sound
    end
  end

  def animate_match_remove
    run_sequence do
      scale_to(0.1, 0.3).ease_out
      remove_from_parent
    end
  end
end

