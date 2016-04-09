require 'pp'
require 'minitest/autorun'

require_relative '../../lib/utilities/math_utils'

class ShortestTurnTest < MiniTest::Test
  def test_shortest_turn
    assert(:clockwise == Paidgeeks::shortest_turn(0.0, Math::PI/2.0), "0 => 90 is clockwise")
    assert(:clockwise == Paidgeeks::shortest_turn(Math::PI/2.0, Math::PI), "90 => 180 is clockwise")
    assert(:clockwise == Paidgeeks::shortest_turn(Math::PI, Paidgeeks::TWOPI * 0.75), "180 => 270 is clockwise")
    assert(:clockwise == Paidgeeks::shortest_turn(Paidgeeks::TWOPI * 0.75, 0.0), "270 => 0 clockwise")

    assert(:counterclockwise == Paidgeeks::shortest_turn(Math::PI/2.0, 0), "90 => 0 is counterclockwise")
    assert(:counterclockwise == Paidgeeks::shortest_turn(Math::PI, Math::PI/2.0), "180 => 90 is counterclockwise")
    assert(:counterclockwise == Paidgeeks::shortest_turn(Paidgeeks::TWOPI * 0.75, Math::PI), "270 => 180 is counterclockwise")
    assert(:counterclockwise == Paidgeeks::shortest_turn(0.0, Paidgeeks::TWOPI * 0.75), "0 => 270 counterclockwise")
  end
end
