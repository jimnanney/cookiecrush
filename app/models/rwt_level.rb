class RWTLevel
  NUM_COLUMNS = 9
  NUM_ROWS = 9

  attr_accessor :maximum_moves, :target_score, :combo_multiplier

  def init_with_file(filename)
    dictionary = self.load_json(filename)
    loaded_tiles = dictionary.objectForKey("tiles")
      loaded_tiles.each_index do |row|
      loaded_tiles[row].each_index do |column|
        tile_row = NUM_ROWS - row - 1
        value = loaded_tiles[row][column].to_i
        tiles[offset(column, tile_row)] = RWTTile.new if value > 0
      end
    end
    self.target_score = dictionary["targetScore"].to_i
    self.maximum_moves = dictionary["moves"].to_i
  end

  def tile_at(column, row)
    raise "Invalid column" unless column >= 0 && column < NUM_COLUMNS
    raise "Invalid row" unless row >= 0 && column < NUM_ROWS
    tiles[offset(column, row)]
  end

  def load_json(filename)
    path = NSBundle.mainBundle.pathForResource(filename, ofType:"json", inDirectory:"Levels")
    error = Pointer.new(:object)
    data = NSData.dataWithContentsOfFile(path, options: 0, error: error)
    unless data
      puts "Could not load level file: #{filename}, error: #{error[0]}"
      return
    end
    dictionary = NSJSONSerialization.JSONObjectWithData(data, options: 0, error: error)
    unless dictionary
      puts "Invalid JSON file: #{filename}, error: #{error[0]}"
      return
    end
    dictionary
  end

  def shuffle
    possible_swaps.removeAllObjects
    set = nil
    while possible_swaps.count == 0 do
      set = create_initial_cookies
      detect_possible_swaps
    end
    set
  end

  def detect_possible_swaps
    cookies.each do |c|
      swap = try_swap(c, true)
      possible_swaps.addObject(swap) if swap
      swap = try_swap(c, false)
      possible_swaps.addObject(swap) if swap
    end
    return
  end

  def try_swap(cookie, forCol)
    return unless cookie
    other_row = forCol ? cookie.row : cookie.row+1
    other_col = forCol ? cookie.column+1 : cookie.column
    return if (forCol && ( cookie.column >= (NUM_COLUMNS - 1)))
    return if (!forCol && (cookie.row >= (NUM_ROWS - 1)))
    other = cookieAtColumn(other_col, other_row)
    return unless other
    possible_swap = RWTSwap.new.tap do |s|
      s.cookie_a = cookie
      s.cookie_b = other
    end
    swap = nil
    cookies[offset(cookie.column, cookie.row)] = possible_swap.cookie_b
    cookies[offset(other.column, other.row)] = possible_swap.cookie_a
    if has_chain_at(other.column, other.row) ||
      has_chain_at(cookie.column, cookie.row)
      swap = RWTSwap.new.tap do |s|
        s.cookie_a = cookie
        s.cookie_b = other
      end
    end
    cookies[offset(cookie.column, cookie.row)] = possible_swap.cookie_a
    cookies[offset(other.column, other.row)] = possible_swap.cookie_b
    swap
  end

  def is_possible_swap?(swap)
    possible_swaps.containsObject(swap)
  end

  def has_chain_at(col, row)
    cookie = cookieAtColumn(col, row)
    return false unless cookie
    return true if col_matches(col, row, cookie.cookie_type, -1) + col_matches(col, row, cookie.cookie_type, 1) + 1 >=3
    return true if row_matches(col, row, cookie.cookie_type, -1) + row_matches(col, row, cookie.cookie_type, 1) + 1 >=3
    false
  end

  def row_matches(col, row, type,  dir)
    matches_count(col, row, type, dir, false)
  end

  def col_matches(col, row, type, dir)
    matches_count(col, row, type, dir, true)
  end

  def matches_count(col, row, type, dir, forCol)
    max = forCol ? NUM_COLUMNS : NUM_ROWS
    start = forCol ? col : row
    matches = 0
    range = (dir > 0) ? (start+dir...max) : (0..start+dir).to_a.reverse
    range.each do |i|
      cookie = forCol ? cookieAtColumn(i, row) : cookieAtColumn(col, i)
      return matches unless cookie && cookie.cookie_type == type
      matches += 1
    end
    matches
  end

  def possible_swaps
    @possible_swaps ||= NSMutableSet.set
  end

  def cookieAtColumn(column, row)
    raise "Invalid column" unless column >= 0 && column < NUM_COLUMNS
    raise "Invalid row" unless row >= 0 && column < NUM_ROWS
    cookies[offset(column, row)]
  end

  def create_initial_cookies
    set = NSMutableSet.set
    (0...NUM_ROWS).each do |row|
      (0...NUM_COLUMNS).each do |column|
        cookie_type = generate_cookie_type(column,row)
        set.addObject create_cookie_at(column, row, cookie_type) if tile_at(column, row)
      end
    end
    set
  end

  def generate_cookie_type(col, row)

    lookup = [
      [0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0],
      [0,0,0,1,2,3,0,0,0],
      [0,0,0,2,4,4,0,0,0],
      [0,0,0,4,2,5,0,0,0],
      [0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0],
    ];
    #return lookup[row][col]
    cookie_type = random_cookie_type
    while (is_chain_to_left?(cookie_type, col, row) ||
           is_chain_below?(cookie_type, col, row)) do
      cookie_type = random_cookie_type
    end
    cookie_type
  end

  def is_chain_to_left?(cookie, col, row)
    col >= 2 && cookie_type(col-1, row) == cookie && cookie_type(col-2, row) == cookie
  end

  def is_chain_below?(cookie, col, row)
    row >= 2 && cookie_type(col, row-1) == cookie && cookie_type(col, row-2) == cookie
  end

  def cookie_type(col, row)
    cookie = cookies[offset(col, row)]
    cookie ? cookie.cookie_type : -1
  end

  def random_cookie_type(excludes=[])
    cookie_type = rand(RWTCookie::NUM_COOKIE_TYPES) + 1
    while excludes.find_index(cookie_type) do
      cookie_type = rand(RWTCookie::NUM_COOKIE_TYPES) + 1
    end
    cookie_type
  end

  def create_cookie_at(column, row, cookie_type)
    cookie = RWTCookie.new.tap do |c|
      c.cookie_type = cookie_type
      c.row = row
      c.column = column
    end
    cookies[offset(column, row)] = cookie
    cookie
  end

  def perform_swap(swap)
    col_a = swap.cookie_a.column
    row_a = swap.cookie_a.row

    col_b = swap.cookie_b.column
    row_b = swap.cookie_b.row

    cookies[offset(col_a, row_a)] = swap.cookie_b
    swap.cookie_b.column = col_a
    swap.cookie_b.row = row_a

    cookies[offset(col_b, row_b)] = swap.cookie_a
    swap.cookie_a.column = col_b
    swap.cookie_a.row = row_b
  end

  def detect_horizontal_matches
    #set = NSMutableSet.set
    set = []
    (0...NUM_ROWS).each do |row|
      col = 0
      while (col < (NUM_COLUMNS - 2)) do
        match_type = cookie_type(col, row)
        if match_type > 0
          if (cookie_type(col + 1, row) == match_type &&
              cookie_type(col + 2, row) == match_type)
            chain = RWTChain.new
            chain.chain_type = RWTChain::HORIZONTAL
            while(col < NUM_COLUMNS && cookie_type(col, row) == match_type) do
              chain.add_cookie(cookieAtColumn(col, row))
              col += 1
            end
            set << chain unless set.include?(chain) #.addObject(chain)
          else
            col += 1
          end
        else
          col += 1
        end
      end
    end
    set
  end

  def detect_vertical_matches
    #set = NSMutableSet.set
    set = []
    (0...NUM_COLUMNS).each do |col|
      row = 0
      while(row < (NUM_ROWS - 2)) do
        match_type = cookie_type(col, row)
        if match_type > 0
          if (cookie_type(col, row + 1) == match_type &&
              cookie_type(col, row + 2) == match_type)
            chain = RWTChain.new
            chain.chain_type = RWTChain::VERTICAL
            while(row < NUM_ROWS && cookie_type(col, row) == match_type) do
              chain.add_cookie(cookieAtColumn(col, row))
              row += 1
            end
            set << chain unless set.include?(chain) #.addObject(chain)
          else
            row += 1
          end
        else
          row += 1
        end
      end
    end
    set
  end

  def detect_matches
    horizontal_chains = detect_horizontal_matches
    vertical_chains = detect_vertical_matches
    results = {h: [], v: [], matches: []}
    in_both = horizontal_chains.reduce(results) do |acc, h|
      match = vertical_chains.first do |v|
        (v.cookies & h.cookies).length > 0
      end
      if match
        vc = match.cookies
        chain = RWTChain.new
        chain.chain_type = RWTChain::T_CHAIN
        chain.chain_type = RWTChain::L_CHAIN if (vc.include?(h.cookies[0]) || vc.include?(h.cookies[-1]))
        chain.cookies = h.cookies | vc #match.cookies
        acc[:matches] << chain #{h: h, v: match}
        acc[:h] << h
        acc[:v] << match
      end
      acc
    end
    #puts results
    horizontal_chains -= results[:h]
    vertical_chains -= results[:v]
    results[:matches]+horizontal_chains+vertical_chains
  end

  def remove_matches
    chains = detect_matches
    remove_cookies(chains)
    calculate_scores(chains)
    return chains

    remove_cookies(results[:matches])
    remove_cookies(horizontal_chains)
    remove_cookies(vertical_chains)
    calculate_scores(results[:matches])
    calculate_scores(horizontal_chains)
    calculate_scores(vertical_chains)
    #horizontal_chains.setByAddingObjectsFromSet(vertical_chains)
    results[:matches]+horizontal_chains+vertical_chains
  end

  def remove_cookies(chains)
    chains.each do |chain|
      chain.cookies.each do |cookie|
        cookies[offset(cookie.column, cookie.row)] = nil if cookie && cookie != NSNull
      end
    end
  end

  def fill_holes
    columns = []
    (0...NUM_COLUMNS).each do |col|
      col_array = []
      (0...NUM_ROWS).each do |row|
        if (tiles[offset(col, row)] && cookies.at(offset(col,row)).nil?)
          ((row+1)...NUM_ROWS).each do |lookup|
            cookie = cookies.at(offset(col, lookup))
            if cookie
              cookies[offset(col, row)] = cookie
              cookies[offset(col, lookup)] = nil
              cookie.row = row
              col_array << cookie
              columns << col_array if col_array.length == 1
              break
            end
          end
        end
      end
    end
    columns
  end

  def top_up_cookies
    columns = []
    previous_cookie_type = 0
    (0...NUM_COLUMNS).each do |col|
      col_array = []
      count = 0
      (0...NUM_ROWS).to_a.reverse.each do |row|
        count += 1 if cookies.at(offset(col, row)).nil?
        break if cookies.at(offset(col,row))
        tile = tiles.at(offset(col, row))
        if tile#.nil? #at(offset(col, row)) > 0
          previous_cookie_type = random_cookie_type([previous_cookie_type])
          cookie = create_cookie_at(col, row, previous_cookie_type)
          columns << col_array unless col_array.length > 0
          col_array << cookie
        end
      end
    end
    #display_cookies
    columns
  end

  def tiles
    @tiles ||= Array.new(NUM_COLUMNS * NUM_ROWS)
  end

  def cookies
    @cookies ||= Array.new(NUM_COLUMNS * NUM_ROWS)
  end

  def display_cookies
    cookies.each_with_index do |cookie, idx|
      puts if (idx % NUM_COLUMNS == 0)
      if cookie
        print " #{cookie.cookie_type}:#{cookie.column},#{cookie.row} "
      else
        print " nil   "
      end
    end
    puts
  end

  def offset(column, row)
    (row * NUM_COLUMNS) + column
  end

  def calculate_scores(chains)
    chains.each do |chain|
      self.combo_multiplier ||= 1
      chain.score = 60 * (chain.cookies.count - 2) * combo_multiplier
      chain.score = chain.score * 2 if (chain.chain_type > 2)
      self.combo_multiplier += 1
    end
  end

  def reset_combo_multiplier
    self.combo_multiplier = 1
  end
end


