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
end
