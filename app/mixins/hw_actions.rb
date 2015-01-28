module HWActions
  module ActionDSL

    class DSL
      attr_accessor :actions

      def initialize(block, parent)
        @actions = []
        @parent = parent
        instance_eval(&block) if block
      end

      def method_missing(name, *args, &block)
        act = nil
        if @parent.respond_to?(name)
          act = @parent.send(name, *args, &block)
          #puts "Act: #{act} name: #{name} args: #{args}"# unless act.is_a?(SKAction)
        else
          act = super
        end
        @actions << act if act.kind_of?(SKAction)
        act
      end

      def respond_to?(name, include_all=false)
        @parent.respond_to?(name) || super
      end
    end

    def run_sequence(&block)
      seq = sequence &block
      runAction seq
    end

    def run_group(&block)
      runAction group(block)
    end
    
    def group(&block)
      grp = DSL.new(block, self)
      SKAction.group(grp.actions)
    end

    def repeat(count, action = nil,  &block)
      seq = (action) ? action : sequence(&block)
      SKAction.repeatAction(seq, count)
    end

    def sequence(&block)
      seq = DSL.new(block, self)
      SKAction.sequence(seq.actions)
    end

    def other_action(other)
      other
    end

    def move_to(location, duration)
      SKAction.moveTo(location, duration: duration)
    end

    def move_by(delta, duration=0.25)
      SKAction.moveBy(delta, duration: duration)
    end

    def fade_in(duration = 0.25)
      SKAction.fadeInWithDuration(duration)
    end

    def fade_out(duration = 0.25)
      SKAction.fadeOutWithDuration(duration)
    end

    def run_block(&block)
      SKAction.runBlock(block)
    end

    def wait(duration = 0.25, with_range = nil)
      return SKAction.waitForDuration(duration) unless with_range
      SKAction.waitForDuration(duration, with_range)
    end

    def scale_to(scale = 1.0, duration=0.25)
      SKAction.scaleTo(scale, duration: duration)
    end

    def remove_from_parent
      SKAction.removeFromParent
    end
  end

  module ActionMix

    def ease_in
      timing_mode = SKActionTimingEaseIn
      self
    end

    def ease_out
      timing_mode = SKActionTimingEaseOut
      self
    end

    def linear
      timing_mode = SKActionTimingLinear
      self
    end

  end

  module SKNodeHelpers
    def mid_x
      CGRectGetMidX(self.frame)
    end

    def mid_y
      CGRectGetMidY(self.frame)
    end

    def height
      CGRectGetHeight(self.frame)
    end

    def width
      CGRectGetWidth(self.frame)
    end

    def top
      CGRectGetMaxY(self.frame)
    end

    def bottom
      CGRectGetMinY(self.frame)
    end

    def left
      CGRectGetMinX(self.frame)
    end

    def right
      CGRectGetMaxX(self.frame)
    end
  end
end

class SKNode
  include HWActions::ActionDSL
  include HWActions::SKNodeHelpers
  alias run_action runAction
end

class SKAction
  include HWActions::ActionMix
end
