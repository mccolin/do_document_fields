# AWEXOME
# DoDocumentFields - tasks for building index migrations, etc.

namespace :db do
  namespace :migrate do
    
    desc "Build index table migrations for any models specifying document fields with indexes"
    task :document_indexes => :environment do

      # Load the models in our application:
      models = Array.new
      wdir = Dir.pwd
      Dir.chdir( File.join(RAILS_ROOT, "app/models") )
      Dir.glob("**/*.rb").each do |filepath|
        filename = File.basename(filepath)        
        model = filename.split(".").first.camelize.constantize
        models << model
      end
      Dir.chdir(wdir)
      puts "INDEX_BUILDER: #{models.length} models found: #{models.inspect}"
      
      # Remove models from list that do not specify document indices:
      models.delete_if do |model|
        !model.respond_to?(:document_indexes) || model.send(:document_indexes).empty?
      end
      puts "INDEX_BUILDER: #{models.length} models declare indexes: #{models.inspect}"
      
      # For each model which specifies any document_indices, build an index table:
      unless models.empty?
        conn = ActiveRecord::Base.connection
        models.each do |model|
          index_table_name = "document_indexes_for_#{model.table_name}"
          puts "INDEX_BUILDER: investigating index #{index_table_name}"
          unless conn.table_exists?(index_table_name)
            puts "INDEX_BUILDER: creating index table #{index_table_name}"
            conn.create_table(index_table_name) do |t|
              t.integer :doc_id, :null=>false
              t.string :field, :null=>false
              t.string :value, :default=>nil
            end
            conn.add_index(index_table_name, [:field, :value])
          else
            puts "INDEX_BUILDER: index table #{index_table_name} already exists"
          end
        end
      end
      
    end
    
  end
end
