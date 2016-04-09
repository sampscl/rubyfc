#! /usr/bin/env ruby

class Foo
  attr_accessor :bar
  def initialize
    @bar = 1
  end
  def test(val)
    self.bar=val
  end
end

foo = Foo.new
foo.test(27)
puts foo.bar