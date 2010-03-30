# AWEXOME
# MissingHash - a Hash reimplementation with direct-access to top-level keys

module Awexome
  module Util
    
    module MissingHash
      def method_missing(method, *args)
        unless method.to_s.scan(/=$/).empty?
          return self[method.to_s.gsub(/=$/,"").to_sym] = args.shift
        else 
          return self[method] if self.keys.include?(method)
        end
        super(method, *args)
      end
    end # MissingHash
    
    
    module CondArray
      def add_condition(cond, conj="AND")
        if cond.is_a?(Array)
          if self.empty?
            (self << cond).flatten!
          else
            self[0] += " #{conj} #{cond.shift}"
            (self << cond).flatten!
          end
        elsif cond.is_a?(String)
          self[0] += " #{conj} #{cond}"
        else
          raise "Condition must be an Array or String"
        end
        self
      end
    end
    
  end # Util
end # Awexome

