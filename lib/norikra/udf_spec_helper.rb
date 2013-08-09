module Norikra::UDFSpecHelper
  @@plugins = {}

  class UDFInstance
    def initialize(classname, methodname)
      @methodname = methodname

      parts = classname.split('.')
      clazzname = parts.pop
      @clazz = eval("Java::" + parts.map(&:capitalize).join + "::" + clazzname)
    end
    def call(*args)
      @clazz.send(@methodname.to_sym, *args)
    end
  end

  def call(name, *args)
    @@plugins[name].call(*args)
  end

  def udf_function(mojule)
    if mojule.is_a?(Class)
      klass = mojule
      klass.init if klass.respond_to?(:init)
      name, classname, methodname = klass.new.definition
      @@plugins[name] = UDFInstance.new(classname, methodname)
    else
      mojule.init if mojule.respond_to?(:init)
      ps = []
      mojule.plugins.each{|p| ps.push(udf_function(p))} if mojule.respond_to?(:plugins)
      ps
    end
  end
end
