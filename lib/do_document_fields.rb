# AWEXOME
# DoDocumentFields - meat and potatoes


module Awexome
  module Do
    module DocumentFields
      
      class NoFieldNameSpecified < Exception
        def initialize(msg="A document field name must be provided to build a document_field"); super(msg); end
      end
      class NoFieldForThatIndex < Exception
        def initialize(msg="A document field must exist before an index can be applied to it"); super(msg); end
      end
            
      
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
          raise NoFieldNameSpecified unless field_name
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
          raise NoFieldNameSpecified unless field_name
          raise NoFieldForThatIndex unless self.send("document_fields").include?(field_name)
          class_name = self.name.underscore
          class_table_name = self.table_name
          index_table_name = "document_indexes_for_#{class_table_name}"
          puts "DOCUMENT_FIELDS:  document_index invoked for \"#{field_name}\" on #{class_name}"
          self.send("document_indexes").send("<<", field_name)
          
          instance_eval <<-EOS
            def find_by_#{field_name}(val)
              find(
                :all, 
                :select=>"*",
                :from=>"#{index_table_name}",
                :conditions=>["`#{index_table_name}`.field = ? AND `#{index_table_name}`.value = ?", "#{field_name}", val], 
                :joins => "LEFT JOIN `#{class_table_name}` ON `#{class_table_name}`.id = `#{index_table_name}`.doc_id"
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

