# AWEXOME
# MissingHash - a Hash reimplementation with direct-access to top-level keys

module Awexome
  module Util
    module MissingHash
      
      def method_missing(method, *args)
        puts "Crackpipe method missing"
        unless method.to_s.scan(/=$/).empty?
          return self[method.to_s.gsub(/=$/,"").to_sym] = args.shift
        else 
          return self[method] if self.keys.include?(method)
        end
        super(method, *args)
      end
      
    end # MissingHash
  end # Util
end # Awexome

