# AWEXOME
# DoDocumentFields - initializer

require 'missing_hash'
require 'do_document_fields'
Hash.class_eval do
  include Awexome::Util::MissingHash
end
ActiveRecord::Base.class_eval do
  include Awexome::Do::DocumentFields
end

