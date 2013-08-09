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

  def udf_function(klass)
    klass.init
    name, classname, methodname = klass.new.definition
    @@plugins[name] = UDFInstance.new(classname, methodname)
  end
end
