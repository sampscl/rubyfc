module Paidgeeks
  def self.class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end

  # Get all class methods, including ancestor class methods, from klass
  # Parameters:
  #   - klass The Class
  # Returns: [:class_method1_atom, ...]
  def self.all_class_methods(klass)
    ancestors = klass.superclass == Object ? Object.methods(false) : Paidgeeks.all_class_methods(klass.superclass)
    (ancestors + klass.methods(false)).uniq
  end
end
