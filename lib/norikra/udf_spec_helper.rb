module Norikra::UDFSpecHelper
  @@plugins = {}

  class UDFInstance
    def initialize(name, classname, methodname, signature)
      @name = name
      @classname = classname
      @methodname = methodname
      parts = @classname.split('.')
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

  def udf_function(name, classname, methodname, signature)
    @@plugins[name] = UDFInstance.new(name, classname, methodname)
  end
end
