# AWEXOME
# DoDocumentFields - initializer

require 'do_document_fields'
ActiveRecord::Base.class_eval do
  include Awexome::Do::DocumentFields
end
