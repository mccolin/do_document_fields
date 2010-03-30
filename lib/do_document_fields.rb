# AWEXOME
# DoDocumentFields - meat and potatoes


module Awexome
  module Do
    module DocumentFields
      
      class NoColumnNameSpecified < Exception
        def initialize(msg="A document column name must be provided to build a document_field."); super(msg); end
      end
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
          extend ClassMethods
          include InstanceMethods
          column_name = args.shift || :document
          puts "DOCUMENT_FIELDS:  do_document_fields turned on for #{self.name} in column #{column_name}"
          serialize "#{column_name}".to_sym, Hash
          
          cattr_accessor :document_column_names
          self.document_column_names ||= Array.new
          self.document_column_names << column_name.to_sym
          
          cattr_accessor :document_fields
          self.document_fields = Array.new
          
          cattr_accessor :document_indexes
          self.document_indexes = Array.new
          
          instance_eval <<-EOS
            def #{column_name}_field(*args)
              self.declare_document_field(*args.unshift(:#{column_name}))
            end
          EOS
          
        end
        
        
        # Attribute declaration. Use this method to declare fields that are stored within
        # the document store for objects of this type. Accessors will be created for the field
        # that manipulate the document store instead of a full-fledged column.
        # * +column_name+ - first argument is the document-store column for to add the field to
        # * +field_name+ - second argument is the name of the field
        # * +field_opts+ - third argument (optional) is a hash of additional field options (type, default, etc.)
        def declare_document_field(*args)
          column_name = args.shift; raise NoColumnNameSpecified unless column_name
          field_name = args.shift;  raise NoFieldNameSpecified unless field_name
          field_opts = args.shift || Hash.new
          puts "DOCUMENT_FIELDS:  declare_document_field invoked for \"#{column_name}\" column with \"#{field_name}\" field"
          self.send("document_fields").send("<<", field_name)
          
          define_method(field_name) do
            puts "DOCUMENT_FIELDS:  accessor invoked for field:#{field_name} on column:#{column_name}"
            document_body = self.send(column_name) || Hash.new
            document_body[field_name]
          end
          define_method("#{field_name}=") do |val|
            puts "DOCUMENT_FIELDS:  updater invoked for field:#{field_name}"
            document_body = self.send(column_name) || Hash.new
            document_body[field_name] = val
            self.send("#{column_name}=", document_body)
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
            class_name = self.class.name.underscore
            class_table_name = self.class.table_name
            index_table_name = "document_indexes_for_#{class_table_name}"
            idx_id = ActiveRecord::Base.connection.insert("INSERT INTO `#{index_table_name}` (`doc_id`,`field`,`value`) VALUES ("+self.id.to_s+", \""+field_name.to_s+"\", \"#{self.send(field_name).to_s}\")")
          end
          after_save "update_document_index_#{field_name}_after_save"
          
          # TODO: Add after_destroy callback to update index
          define_method("update_document_index_#{field_name}_after_destroy") do
            puts "DOCUMENT_FIELDS:  update_document_index_after_destroy invoked for \"#{field_name}\"; not yet implemented"
            class_name = self.class.name.underscore
            class_table_name = self.class.table_name
            index_table_name = "document_indexes_for_#{class_table_name}"
            num_del = conn.delete("DELETE FROM `#{index_table_name}` WHERE `doc_id` = #{self.id}")
          end
          after_destroy "update_document_index_#{field_name}_after_destroy"
          
        end
        
      end # ClassMethods
      
      
      module InstanceMethods
        
        def perform_index_find(index_table_name)
          table
        end
        
      end #InstanceMethods
      
      
    end # DocumentFields
  end # Do
end # Awexome

