class RWTSwap
  attr_accessor :cookie_a, :cookie_b

  def to_s
    "Swap #{cookie_a} with #{cookie_b}"
  end

  def isEqual(other)
    return false unless other.kind_of? RWTSwap
    other.cookie_a == cookie_a && other.cookie_b == cookie_b ||
      other.cookie_a == cookie_b && other.cookie_b == cookie_a
  end

  def hash
    return cookie_a.hash ^ cookie_b.hash
  end

  def animate_show_swap
    cookie_a.repeat(3) do
      reverse do
        sequence do
          scale_by 0.3, 0.3
          wait 0.3
        end
      end
    end
  end

end
