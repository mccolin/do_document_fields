# AWEXOME
# DoDocumentFields - meat and potatoes


module Awexome
  module Do
    module DocumentFields
      
      class NoFieldName < Exception; end
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        
        # Class-level initializer
        # * +column+ - first argument specifies the column to use for document storage
        def do_document_fields(*args)
          puts "DOCUMENT_FIELDS:  do_document_fields turned on for #{self.name}"
          extend ClassMethods
          include InstanceMethods
          column_name = args.shift || :document
          serialize "#{column_name}".to_sym, Hash
          cattr_accessor :document_column_name
          self.document_column_name = column_name.to_sym
          cattr_accessor :document_fields
          self.document_fields = Array.new
          cattr_accessor :document_indexes
          self.document_indexes = Array.new
        end
        
        
        # Attribute declaration. Use this method to declare fields that are stored within
        # the document store for objects of this type. Accessors will be created for the field
        # that manipulate the document store instead of a full-fledged column.
        # * +field_name+ - first argument is the name of the field
        # * +field_type+ - second argument (optional) is the data type of the field
        def document_field(*args)
          field_name = args.shift
          raise(NoFieldName, "A document field name must be provided to build a document_field") unless field_name
          field_type = args.shift
          puts "DOCUMENT_FIELDS:  document_field invoked for \"#{field_name}\""
          self.send("document_fields").send("<<", field_name)
          define_method(field_name) do
            puts "DOCUMENT_FIELDS:  accessor invoked for \"#{field_name}\""
            document_body = self.send(document_column_name) || Hash.new
            document_body[field_name]
          end
          define_method("#{field_name}=") do |val|
            puts "DOCUMENT_FIELDS:  updater invoked for \"#{field_name}\""
            document_body = self.send(document_column_name) || Hash.new
            document_body[field_name] = val
            self.send("#{document_column_name}=", document_body)
          end
        end
        
        
        # Index declaration. Use this method to add an index on the given field from within
        # the document store. Indexes are created in an additional table that can be queried
        # to optimize searches and queries for document objects.
        # * +field_name+ - the name of the field for which to add an index
        def document_index(*args)
          field_name = args.shift
          raise(NoFieldName, "A document field name must be provided to build a document_index") unless field_name
          class_name = self.name.downcase
          index_table_name = "index_#{field_name}_in_#{class_name}"
          puts "DOCUMENT_FIELDS:  document_index invoked for \"#{field_name}\" on #{class_name}"
          self.send("document_indexes").send("<<", field_name)
          
          instance_eval <<-EOS
            def find_by_#{field_name}(val)
              #puts "DOCUMENT_FIELDS:  indexed finder invoked for \"#{field_name}\" on #{class_name}"
              find(
                :all, 
                :select=>"*",
                :from=>"#{index_table_name}",
                :conditions=>["`#{index_table_name}`.value = ?", val], 
                :joins => "LEFT JOIN `#{class_name}s` ON `#{class_name}s`.id = `#{index_table_name}`.doc_id"
              )
            end
          EOS
          
          # TODO: Add after_save callback to update index
          define_method("update_document_index_#{field_name}_after_save") do
            puts "DOCUMENT_FIELDS:  update_document_index_after_save invoked for \"#{field_name}\"; not yet implemented"
          end
          after_save "update_document_index_#{field_name}_after_save"
          
          # TODO: Add after_destroy callback to update index
          define_method("update_document_index_#{field_name}_after_destroy") do
            puts "DOCUMENT_FIELDS:  update_document_index_after_destroy invoked for \"#{field_name}\"; not yet implemented"
          end
          after_destroy "update_document_index_#{field_name}_after_destroy"
          
        end
        
      end # ClassMethods
      
      
      module InstanceMethods
      end #InstanceMethods
      
      
    end # DocumentFields
  end # Do
end # Awexome



# module Awexome
#   module Do
#     module DocumentFields
#       def self.included(mod)
#         mod.extend(ClassMethods)
#       end
#       
#       # Helper methods for the ActiveRecord class implementing DocumentFields
#       module ClassMethods
#         
#         # Class-level initializer
#         # * +column+ - first argument specifies the column to use for document storage
#         def do_document_fields(*args)
#           column_name = args.shift || :document
#           puts "DOCUMENT_FIELDS:  do_document_fields invoked for #{column_name}"
#           class_eval <<-EOV
#             include Awexome::Do::DocumentFields::InstanceMethods
#             serialize :#{column_name}, Hash
#             attr_accessor :document_fields
#             def document_column_name
#               '#{column_name}'
#             end
#           EOV
#         end
#         
#         # Attribute declaration. Use this method to declare fields that are stored within
#         # the document store for objects of this type. Accessors will be created for the field
#         # that manipulate the document store instead of a full-fledged column.
#         # * +field_name+ - first argument is the name of the field
#         # * +field_type+ - second argument (optional) is the data type of the field
#         def document_field(*args)
#           puts "DOCUMENT_FIELDS:  document_field invoked for \"#{args.inspect}\""
#           field_name = args.shift
#           field_type = args.shift
#           class_eval <<-EOV
#             def #{field_name}()
#               document_body = self.send(document_column_name) || {}
#               document_body[:#{field_name}]
#             end
#             def #{field_name}=(val)
#               document_body = self.send(document_column_name) || Hash.new
#               document_body[:#{field_name}] = val
#               self.send(document_column_name+"=", document_body)
#             end
#           EOV
#         end
#         
#         
#         # Index declaration. Use this method to add an index on the given field from within
#         # the document store. Indexes are created in an additional table that can be queried
#         # to optimize searches and queries for document objects.
#         # * +field_name+ - the name of the field for which to add an index
#         def document_index(field_name)
#           puts "DOCUMENT_FIELDS:  document_index invoked for \"#{field_name}\"; not yet implemented"
#         end
#         
#       end
# 
# 
#       # Instance methods for use by the ActiveRecord class with document fields
#       module InstanceMethods
#       end
#       
#     end
#   end
# end

