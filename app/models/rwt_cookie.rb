class RWTCookie
  NUM_COOKIE_TYPES = 6
  SPRITE_NAMES = ['Croissant', 'Cupcake', 'Danish',
                 'Donut', 'Macaroon', 'SugarCookie']
  HIGHLIGHTED_SPRITE_NAMES = [
    'Croissant-Highlighted',
    'Cupcake-Highlighted',
    'Danish-Highlighted',
    'Donut-Highlighted',
    'Macaroon-Highlighted',
    'SugarCookie-Highlighted']

  attr_accessor :column, :row, :cookie_type, :sprite

  def sprite_name
    SPRITE_NAMES[cookie_type-1]
  end

  def highlighted_sprite_name
    HIGHLIGHTED_SPRITE_NAMES[cookie_type-1]
  end

  def to_s
    "RWTCookie: square: (#{column}, #{row}) #{cookie_type}(#{sprite_name})"
  end
end
