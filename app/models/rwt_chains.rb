class RWTChain
  attr_accessor :chain_type, :cookies, :score

  HORIZONTAL = 1
  VERTICAL = 2
  T_CHAIN = 3
  L_CHAIN = 4

  def initialize
    @cookies = []
  end

  def add_cookie(cookie)
    @cookies ||= []
    @cookies << cookie
  end

  def to_s
    "Type: #{chain_type} cookies: #{cookies}"
  end

  def animate_score(layer)
    return animate_all_scores(layer) unless (chain_type == HORIZONTAL || chain_type == VERTICAL)
    score_label(score, layer, midpoint)
  end

  private

  def midpoint
    first = cookies[0].sprite.position
    last = cookies[-1].sprite.position
    center = CGPointMake((first.x + last.x)/2, (first.y + last.y)/2 - 8)
  end

  def animate_all_scores(layer)
    score_per_tile = score / cookies.length
    cookies.each { |c| score_label(score_per_tile, layer, c.sprite.position) }
  end

  def score_label(score, layer, position)
    score_label = ShadowLabel.labelNodeWithFontNamed("GillSans-BoldItalic").tap do |s|
      s.offset = [3,-3]
      s.blur_radius = 3
      s.shadow_color = UIColor.blackColor
      s.fontColor = UIColor.blueColor
      s.position = position
      s.fontSize = 16 * layer.scene.scale
      s.text = "#{score}"
      s.zPosition = 300
    end
    layer.addChild score_label
    run_score_animation score_label
  end

  def run_score_animation(label)
    label.unobserve_all
    label.run_sequence do
      move_by(CGVectorMake(0,3), 0.7).ease_out
      remove_from_parent
    end
  end

end
