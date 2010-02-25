# AWEXOME
# DoDocumentFields - meat and potatoes

module Awexome
  module Do
    module DocumentFields
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      # Helper methods for the ActiveRecord class implementing DocumentFields
      module ClassMethods
        
        # Class-level initializer
        # * +column+ - first argument specifies the column to use for document storage
        def do_document_fields(*args)
          column_name = args.shift || :document
          puts "DOCUMENT_FIELDS:  do_document_fields invoked for #{column_name}"
          class_eval <<-EOV
            include Awexome::Do::DocumentFields::InstanceMethods
            serialize :#{column_name}, Hash
            def document_column_name
              '#{column_name}'
            end
          EOV
        end
        
        # Attribute declaration. Use this method to declare fields that are stored within
        # the document store for objects of this type. Accessors will be created for the field
        # that manipulate the document store instead of a full-fledged column.
        # * +field_name+ - first argument is the name of the field
        # * +field_type+ - second argument (optional) is the data type of the field
        def document_field(*args)
          puts "DOCUMENT_FIELDS:  document_field invoked for \"#{args.inspect}\""
          field_name = args.shift
          field_type = args.shift
          
          class_eval <<-EOV
            def #{field_name}()
              document_body = self.send(document_column_name) || {}
              document_body[:#{field_name}]
            end
            def #{field_name}=(val)
              document_body = self.send(document_column_name) || Hash.new
              document_body[:#{field_name}] = val
              self.send(document_column_name+"=", document_body)
            end
          EOV
        end
        
        
        # Index declaration. Use this method to add an index on the given field from within
        # the document store. Indexes are created in an additional table that can be queried
        # to optimize searches and queries for document objects.
        # * +field_name+ - the name of the field for which to add an index
        def document_index(field_name)
          puts "DOCUMENT_FIELDS:  document_index invoked for \"#{field_name}\"; not yet implemented"
        end
        
      end


      # Instance methods for use by the ActiveRecord class with document fields
      module InstanceMethods
      end
      
    end
  end
end

