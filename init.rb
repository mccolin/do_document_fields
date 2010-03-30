# AWEXOME
# DoDocumentFields - initializer

require 'utils'
require 'do_document_fields'
Hash.class_eval do
  include Awexome::Util::MissingHash
end
Array.class_eval do
  include Awexome::Util::CondArray
end
ActiveRecord::Base.class_eval do
  include Awexome::Do::DocumentFields
end

