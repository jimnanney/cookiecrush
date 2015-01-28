class ShadowLabel < SKLabelNode

  PROPERTIES = [:shadow_color, :offset, :blur_radius]
  OBSERVED_PROPERTIES = ["text", "fontName", "fontSize",
                         "verticalAlignmentMode",
                         "horizontalAlignmentMode",
                         "fontColor", "zPosition"]
  attr_accessor *PROPERTIES

  def initWithFontNamed(font_name)
    if super
      self.fontColor = UIColor.blackColor
      @offset = CGPointMake(-1, -1)
      @blur_radius = 3
      @shadow_color = UIColor.darkGrayColor.colorWithAlphaComponent(0.8)
      OBSERVED_PROPERTIES.each do |key_path|
        addObserver(self, forKeyPath:key_path, options:NSKeyValueObservingOptionNew, context:nil)
      end
      hasObservers = true
    end
    self
  end

  def update_shadow
    effect = childNodeWithName("shadow_effect") || create_effect_node
    effect.filter = gaussion_blur
    effect.removeAllChildren
    effect.addChild duplicate_label
    insertChild(effect, atIndex:0)
  end

  def unobserve_all
    OBSERVED_PROPERTIES.each do |key_path|
      removeObserver(self, forKeyPath: key_path)
    end
  end

  def observeValueForKeyPath(keypath, ofObject: obj, change:change, context:context)
    self.update_shadow
  end

  def shadow_color=(new_color)
    @shadow_color = new_color
    update_shadow
  end
  
  def offset=(new_offset)
    @offset = new_offset
    update_shadow
  end

  def blur_radius=(new_blur_radius)
    @blur_radius = new_blur_radius
    update_shadow
  end

  def align_center
    self.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter
  end

  def align_right
    self.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight
  end

  def align_left
    self.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft
  end

  def valign_center
    self.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter
  end

  def valign_top
    self.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop
  end

  def valign_bottom
    self.verticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline
  end

  def valign_baseline
    self.verticalAlignmentMode = SKLabelVerticalAlignmentModeBaseline
  end

  private

  def create_effect_node
    node = SKEffectNode.node
    node.name = "shadow_effect"
    node.shouldEnableEffects = true
    node.zPosition = self.zPosition - 1
    node
  end

  def gaussion_blur
    filter = CIFilter.filterWithName "CIGaussianBlur"
    filter.setDefaults;
    filter.setValue(@blur_radius, forKey:"inputRadius")
    filter
  end

  def duplicate_label
    node = SKLabelNode.labelNodeWithFontNamed self.fontName
    node.text = self.text
    node.fontSize = self.fontSize
    node.verticalAlignmentMode = self.verticalAlignmentMode
    node.horizontalAlignmentMode = self.horizontalAlignmentMode
    node.fontColor = shadow_color
    node.position = offset
    node
  end

end
