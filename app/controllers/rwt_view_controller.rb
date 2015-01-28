class RWTViewController < UIViewController
  attr_accessor :level, :scene, :moves_left, :score, :game_over_panel, :tap_gesture_recognizer, :background_music

  def prefersStatusBarHidden
    true
  end

  def loadView
    view = SKView.new
    view.showsFPS = true
    view.showsNodeCount = true
    view.showsDrawCount = true
    view.multipleTouchEnabled = false;
    self.view = view
  end

  def viewWillLayoutSubviews
    super
    unless self.view.scene
      @scene = RWTMyScene.alloc.initWithSize(view.bounds.size)
      #@scene.scaleMode = SKSceneScaleModeAspectFill
      #@scene.scaleMode = SKSceneScaleModeAspectFit
      #@scene.scaleMode = SKSceneScaleModeFill
      @scene.scaleMode = SKSceneScaleModeResizeFill
      @level = RWTLevel.new #init_with_file("Level_1")
      @level.init_with_file("Level_1")
      @scene.level = @level
      @scene.add_tiles
      @scene.swipe_handler = lambda do |swap|
        view.userInteractionEnabled = false
        if @level.is_possible_swap?(swap)
          @level.perform_swap(swap)
          @scene.animate_swap(swap) do
            handle_matches
          end
        else
          @scene.animate_invalid_swap(swap) do
            view.userInteractionEnabled = true
          end
        end
      end
      make_game_over_panel
      game_over_panel.hidden = true
      view.presentScene @scene
      start_background_music
      begin_game
    end
  end

  def start_background_music
    url = NSBundle.mainBundle.URLForResource("Usteczka", withExtension: "mp3")
    self.background_music = AVAudioPlayer.alloc.initWithContentsOfURL(url, error:nil)
    background_music.numberOfLoops = -1
    background_music.volume = 0.5
    background_music.play
  end

  def show_game_over
    @scene.animate_game_over
    game_over_panel.hidden = false
    @scene.userInteractionEnabled = false
    self.tap_gesture_recognizer = UITapGestureRecognizer.alloc.initWithTarget(self, action:'hide_game_over')
    view.addGestureRecognizer(tap_gesture_recognizer)
  end

  def hide_game_over
    view.removeGestureRecognizer(tap_gesture_recognizer)
    self.tap_gesture_recognizer = nil
    game_over_panel.hidden = true
    @scene.userInteractionEnabled = true

    begin_game
  end

  def make_game_over_panel
    self.game_over_panel = UIImageView.alloc.initWithFrame(centered_rect_of_size(320,150))
    #game_over_panel.autoResizingMask = UIViewAutoresizingNone
    view.addSubview(game_over_panel)
  end

  def centered_rect_of_size(width, height)
    x = (view.frame.size.width - width) / 2
    y = (view.frame.size.height - height) / 2
    CGRectMake(x, y, width, height)
  end

  def begin_game
    self.moves_left = @level.maximum_moves
    self.score = 0
    update_labels
    @level.reset_combo_multiplier
    @scene.animate_begin_game
    shuffle
  end

  def update_labels
    @scene.update_labels(moves_left, score, @level.target_score)
  end

  def shuffle
    @scene.remove_all_cookie_sprites
    @scene.add_sprites_for_cookies(@level.shuffle)
  end

  def handle_matches
    chains = @level.remove_matches
    return begin_next_turn if chains.count == 0
    @scene.animate_matched_cookies(chains) do
      chains.each { |chain| self.score += chain.score }
      update_labels
      columns = @level.fill_holes
      @scene.animate_falling_cookies(columns) do
        columns = @level.top_up_cookies
        @scene.animate_new_cookies(columns) do
          handle_matches
        end
      end
    end
  end

  def begin_next_turn
    @level.reset_combo_multiplier
    @level.detect_possible_swaps
    decrement_moves
    if (@level.possible_swaps.count == 0)
      shuffle
      begin_next_turn
    end
    view.userInteractionEnabled = true
  end

  def viewWillTransitionToSize(new_size, withTransitionCoordinator:tc)
    puts "viewWillTransitionToSize: #{new_size.width}, #{new_size.height}"
    puts "                old_size: #{view.size.width}, #{view.size.height}"
    #@scene.update_layout(new_size)
    super
  end

  def decrement_moves
    self.moves_left -=1
    update_labels
    return level_complete if score > @level.target_score
    return game_over if moves_left == 0
  end

  def level_complete
    game_over_panel.image = UIImage.imageNamed("LevelComplete")
    show_game_over
  end

  def game_over
    game_over_panel.image = UIImage.imageNamed("GameOver")
    show_game_over
  end
end

