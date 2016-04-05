module Paidgeeks
  class PassThrough
    def method_missing(method, *args)
      nil
    end
  end
end
