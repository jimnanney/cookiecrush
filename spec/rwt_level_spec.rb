describe "Level" do

  before do
    class RWTLevel
      attr_accessor :cookie_values
      alias prev_random  random_cookie_type
      def cookie_values
        @cookie_values ||= []
      end
      
      def random_cookie_type(excludes =[])
        raise "Out of cookie_values" if cookie_values.empty?
        cookie_values.pop
      end
    end

    @level = RWTLevel.new 
    # 9 tile example level
    @level.init_with_file("Level_4")
  end

  def setup_game_board(board, level)
    board.each_with_index do |row, row_pos|
      row.each_with_index {|type, col| level.create_cookie_at(col, row_pos, type) }
    end
  end

  context "public api" do
    [:detect_matches, :tiles, :cookies, :fill_holes, :remove_matches,
     :remove_cookies, :maximum_moves, :combo_multiplier, :target_score].each do |method|
      it "should respond to #{method}" do
        @level.respond_to?(method).should == true
      end
    end
  end

  context "init_with_file" do
    it "sets maximum moves allowed" do
      @level.maximum_moves.should == 15
    end
    
    it "sets target score" do
      @level.target_score.should == 1000
    end

    it "creates tiles layout" do
      @level.tiles.compact.size.should == 9
    end
  end

  context "shuffle" do
    before do
      @level.cookie_values += SHUFFLE_WITH_MATCH
      @level.shuffle
    end

    it "sets up the cookies on the game board" do
      @level.cookies.compact.count.should == 9
    end

    it "should eliminate any matches in the setup" do
      @level.detect_matches.count.should == 0
    end
  end

  context "swap list" do
    before do
      setup_game_board VERTICAL_MATCH, @level
    end

    it "maintains a list of possible swaps" do
      @level.possible_swaps.nil?.should == false
    end

    it "detects possible swaps" do
      @level.detect_possible_swaps
      @level.possible_swaps.count.should == 1
    end
  end

  context "detect_matches" do
    ["vertical", "horizontal", "L", "T", "plus"].each do |board|
      it "detects #{board} matches correctly" do
        setup_game_board Object.const_get("#{board.upcase}_MATCH"), @level 
        @level.detect_matches.count.should == 1
      end
    end
  end
 
end
