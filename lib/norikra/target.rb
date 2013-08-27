module Norikra
  class Target
    def self.valid?(target_name)
      target_name =~ /^[a-zA-Z]([_a-zA-Z0-9]*[a-zA-Z0-9])?$/
    end
  end
end
