class RWTMyScene < SKScene

  SWIPE_NONE, SWIPE_UP, SWIPE_RIGHT, SWIPE_DOWN, SWIPE_LEFT = [0,1,2,3,4]

  PROPERTIES = [ :level, :game_layer, :cookies_layer, :swipe_handler, :mask_layer, :crop_layer]
  attr_accessor *PROPERTIES

  def initWithSize(size)
    super
    self.anchorPoint = CGPointMake(0.5, 0.5)
    background = SKSpriteNode.spriteNodeWithImageNamed("Background")
    background.zPosition = -3
    background.scale = scale
    addChild background
    @game_layer = SKNode.node
    @game_layer.hidden = true
    addChild @game_layer
    layer_position = CGPointMake(-tile_width*RWTLevel::NUM_COLUMNS/2, -tile_height*RWTLevel::NUM_ROWS/2)
    @tiles_layer = SKNode.node
    @tiles_layer.position = layer_position
    @game_layer.addChild @tiles_layer

    @crop_layer = SKCropNode.alloc.init
    @mask_layer = SKNode.node
    @mask_layer.position = layer_position
    @crop_layer.maskNode = @mask_layer
    @game_layer.addChild @crop_layer


    @cookies_layer = SKNode.node
    @cookies_layer.position = layer_position
    #@crop_layer.addChild @mask_layer
    @crop_layer.addChild @cookies_layer
    @swipe_from_column = @swipe_from_row = NSNotFound
    preload_resources
    setup_score_labels

    self
  end

  def is_phone?
    @is_phone ||= UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone
  end

  def tile_width
    @tile_width ||= (is_phone?) ? 32.0 : 64.0
  end

  def tile_height
    @tile_height ||= (is_phone?) ? 36.0 : 72.0
  end

  def scale
    @scale ||= (is_phone?) ? 1.0 : 2.0
  end

  def touchesBegan(touches, withEvent: event)
    touch = touches.anyObject
    location = touch.locationInNode @cookies_layer
    if (point_in_grid?(location))
      column, row  = grid_location_from_point(location)
      cookie = @level.cookieAtColumn(column, row)
      if cookie 
        show_selection_indicator_for_cookie(cookie)
        @swipe_from_column, @swipe_from_row = grid_location_from_point(location)
      end
    end
  end

  def touchesMoved(touches, withEvent: event)
    return if @swipe_from_column == NSNotFound
    touch = touches.anyObject
    location = touch.locationInNode(@cookies_layer)
    return unless point_in_grid?(location)
    direction = swipe_direction(grid_location_from_point(location))
    if direction[:v] != direction[:h]
      try_swap(direction)
      hide_selection_indicator
      @swipe_from_column = NSNotFound
    end
  end

  def touchesEnded(touches, withEvent: event)
    hide_selection_indicator if selection_sprite.parent && @swipe_from_column != NSNotFound
    @swipe_from_column = @swipe_from_row = NSNotFound
  end

  def touchesCancelled(touches, withEvent: event)
    touchesEnded(touches, withEvent: event)
  end

  def swipe_direction(point)
    column, row = point[0], point[1]
    delta = { h: 0, v: 0 }
    if column < @swipe_from_column
      delta[:h] = -1
    elsif column > @swipe_from_column
      delta[:h] = 1
    elsif row < @swipe_from_row
      delta[:v] = -1
    elsif row > @swipe_from_row
      delta[:v] = 1
    end
    return delta
  end

  def try_swap(direction)
    return if direction[:h] == direction[:v]
    toColumn = @swipe_from_column + direction[:h]
    toRow = @swipe_from_row + direction[:v]
    return if !grid_location_in_grid?(toColumn, toRow)
    toCookie = @level.cookieAtColumn(toColumn, toRow)
    fromCookie = @level.cookieAtColumn(@swipe_from_column, @swipe_from_row)
    return unless toCookie && fromCookie
    if swipe_handler
      swap = RWTSwap.new.tap do |s|
        s.cookie_a = fromCookie
        s.cookie_b = toCookie
      end
      swipe_handler.call(swap)
    end
  end

  def add_sprites_for_cookies(cookies)
    cookies.each do |cookie|
      pos = point_for(cookie.column, cookie.row)
      sprite = CookieNode.init_with_image(cookie.sprite_name, scale, pos)
      sprite.pre_shuffle_setup
      @cookies_layer.addChild(sprite)
      cookie.sprite = sprite
      sprite.animate_cookie_appear
    end
  end

  def tile_at(col, row)
    (@level.tile_at(col, row)) ? 1 : 0
  end

  def add_tiles
    add_tiles_mask
    0.upto(RWTLevel::NUM_ROWS).each do |row|
      0.upto(RWTLevel::NUM_COLUMNS).each do |column|
        tl = column > 0 && row < RWTLevel::NUM_ROWS  && tile_at(column - 1, row) == 1 ? 1 : 0
        bl = column > 0 && row > 0 && tile_at(column - 1, row - 1) == 1 ? 4 : 0
        tr = column < RWTLevel::NUM_COLUMNS && row < RWTLevel::NUM_ROWS && tile_at(column, row) == 1 ? 2 : 0
        br = column < RWTLevel::NUM_COLUMNS && row > 0 && tile_at(column, row - 1) == 1 ? 8 : 0

        #tl = tile_at(column - 1, row)
        #tr = tile_at(column, row) << 1
        #bl = tile_at(column - 1, row - 1) << 2
        #br = tile_at(column, row - 1) << 3
        rounded_tile_number = tl + tr + bl + br
        #puts "[#{column}, #{row}] tl: #{tl} tr: #{tr} bl: #{bl} br: #{br} r: #{rounded_tile_number}"


        if (![0,6,9].include?(rounded_tile_number))

        #if @level.tile_at(column, row)
          tile_node = SKSpriteNode.spriteNodeWithImageNamed("Tile_#{rounded_tile_number}")
          tile_node.scale = scale
          point = point_for(column, row)
          point.x -= tile_width / 2
          point.y -= tile_height / 2
          tile_node.position = point
          @tiles_layer.addChild(tile_node)
        end
      end
    end
  end

  def add_tiles_mask
    (0...RWTLevel::NUM_ROWS).each do |row|
      (0...RWTLevel::NUM_COLUMNS).each do |column|
        if @level.tile_at(column, row)
          tile_node = SKSpriteNode.spriteNodeWithImageNamed("MaskTile")
          tile_node.scale = scale
          tile_node.position = point_for(column, row)
          @mask_layer.addChild(tile_node)
        end
      end
    end

  end

  def animate_swap(swap, &block)
    from = swap.cookie_b.sprite
    to = swap.cookie_a.sprite
    fpos = from.position
    tpos = to.position
    from.zPosition = 90 
    to.zPosition = 100
    to.run_sequence do
      move_to(fpos, 0.3).ease_out
      run_block &block
    end
    from.run_action move_to(to.position,0.3).ease_out
    run_action @swap_sound
  end

  def show_selection_indicator_for_cookie(cookie)
    selection_sprite.removeFromParent if selection_sprite.parent
    texture = SKTexture.textureWithImageNamed(cookie.highlighted_sprite_name)
    selection_sprite.size = texture.size
    selection_sprite.runAction(SKAction.setTexture(texture))
    cookie.sprite.addChild(selection_sprite)
    selection_sprite.alpha = 1.0
  end

  def animate_invalid_swap(swap, &block)
    swap.cookie_a.sprite.zPosition = 100
    swap.cookie_b.sprite.zPosition = 90
    swap.cookie_a.sprite.run_sequence do
      move_to(swap.cookie_b.sprite.position, 0.2).ease_out
      move_to(swap.cookie_a.sprite.position, 0.2).ease_out
      run_block &block
    end
    swap.cookie_b.sprite.run_sequence do
      move_to(swap.cookie_a.sprite.position, 0.2).ease_out
      move_to(swap.cookie_b.sprite.position, 0.2).ease_out
    end
    runAction @invalid_swap_sound
  end

  def animate_matched_cookies(chains, &block)
    chains.each do |chain|
      chain.animate_score @cookies_layer
      chain.cookies.each do |cookie|
        cookie.sprite.animate_match_remove unless cookie.sprite.nil?
        cookie.sprite = nil
      end
    end
    runAction(@match_sound)
    run_after_delay(0.3, &block)
  end

  def animate_falling_cookies(columns, &block)
    longest = 0
    columns.each do |ary|
      ary.each_with_index do |cookie, idx|
        new_position = point_for(cookie.column, cookie.row)
        delay = 0.05 + 0.15*idx
        duration = (cookie.sprite.position.y - new_position.y) / tile_height * 0.1
        longest = (longest > duration + delay) ? longest : duration + delay
        cookie.sprite.animate_fall(new_position, duration, delay, @falling_cookie_sound)
      end
    end
    run_after_delay(longest, &block)
  end

  def animate_new_cookies(columns, &block)
    longest = 0
    columns.each do |cookies|
      start_row = cookies[0].row+1 if cookies.length > 0
      cookies.each_with_index do |cookie, idx|
        start_position = point_for(cookie.column, start_row)
        sprite = CookieNode.init_with_image(cookie.sprite_name, scale, start_position)
        @cookies_layer.addChild sprite
        delay = 0.1 + 0.2*(cookies.count - idx - 1)
        duration = (start_row - cookie.row)* 0.1
        longest = (longest > duration + delay) ? longest : duration + delay
        new_position = point_for(cookie.column, cookie.row)
        sprite.animate_new(new_position, duration, delay, @addCookieSound)
        cookie.sprite = sprite
      end
    end
    run_after_delay(longest, &block)
  end

  def run_after_delay(duration, &block)
    run_sequence do
      wait duration
      run_block &block
    end
  end

  def animate_game_over
    game_layer.runAction SKAction.moveBy(CGVectorMake(0, -self.size.height), duration: 0.3).ease_in
  end

  def animate_begin_game
    game_layer.hidden = false
    game_layer.position = CGPointMake(0, self.size.height)
    game_layer.runAction SKAction.moveBy(CGVectorMake(0, -self.size.height), duration: 0.3)
  end

  def hide_selection_indicator
    selection_sprite.run_sequence do
      fade_out 0.3
      remove_from_parent
    end
  end

  def grid_location_from_point(point)
    return [(point.x / tile_width).to_i, (point.y / tile_height).to_i]
  end

  def point_in_grid?(point)
    return point.x >= 0 && point.x < tile_width * RWTLevel::NUM_COLUMNS &&
      point.y >= 0 && point.y < tile_height * RWTLevel::NUM_ROWS
  end
  
  def grid_location_in_grid?(column, row)
    return column >=0 && column < RWTLevel::NUM_COLUMNS &&
      row >= 0 && row < RWTLevel::NUM_ROWS
  end

  def point_for(column, row)
    CGPointMake(column*tile_width + tile_width/2, row*tile_height+tile_height/2)
  end

  def selection_sprite
    @selection_sprite ||= SKSpriteNode.node
  end

  def preload_resources
    @swap_sound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    @invalid_swap_sound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    @match_sound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    @falling_cookie_sound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    @addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
  end

  def didChangeSize(old_size)
    return if @game_layer.nil?
  end

  def update_layout(size)
    new_frame = @game_layer.calculateAccumulatedFrame
  end

  def setup_score_labels
    score_label = add_label("Score", "score_label", 14, [column_midx(3), top - margin])
    addChild(score_label)
    score_value = add_label("000000", "score_value", 20, [column_midx(3), score_label.bottom - margin])
    addChild(score_value)

    moves_label = add_label("Moves", "moves_label", 14, [column_midx(2), top - margin])
    addChild(moves_label)
    moves_value = add_label("000000", "moves_value", 20, [column_midx(2), moves_label.bottom - margin])
    addChild(moves_value)
    goal_label = add_label("Goal", "goal_label", 14, [column_midx(1), top - margin])
    addChild(goal_label)
    goal_value = add_label("000000", "goal_value", 20, [column_midx(1), goal_label.bottom - margin])
    addChild(goal_value)
  end

  def column_midx(col)
    avail = width - margin*2
    col_size = avail / 3
    col_left = col_size * col + margin
    center = col_left - col_size / 2
    center - (width / 2)  # Since origin is center, we have to account for it here
  end

  def add_label(text, name, font_size, position)
    font_size = font_size * 2 unless is_phone?
    label = ShadowLabel.labelNodeWithFontNamed("Gill Sans Bold")
    label.fontSize = font_size
    label.fontColor = UIColor.whiteColor
    label.offset = [2,-2]
    label.blur_radius = 3
    label.text = text
    label.position = CGPointMake(position[0], position[1])
    label.name = name
    label.valign_top
    label.align_center
    label
  end

  def update_labels(moves, score, goal)
    childNodeWithName("score_value").text = score.to_s
    childNodeWithName("moves_value").text = moves.to_s
    childNodeWithName("goal_value").text = goal.to_s
  end

  def remove_all_cookie_sprites
    @cookies_layer.removeAllChildren
  end

  def margin
    @margin ||= is_phone? ? 10.0 : 20.0
  end

end

