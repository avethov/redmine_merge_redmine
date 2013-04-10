class SourceWiki < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "wikis"

  def self.migrate
    all.each do |source_wiki|

      puts "source_wiki.project_id: #{source_wiki.project_id}"
      project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_wiki.project_id))
      puts "migrated project: #{project.name}"
      wiki = Wiki.find_by_project_id(project.id)
      
      # If the wiki already exists don't add it
      if !wiki            
        puts "Create the wiki for migrated project: #{project.name} "
        wiki = Wiki.create!(source_wiki.attributes) do |w|
          w.project = project
        end      
      end
              
      puts "Adding wiki to map, source_wiki.id: #{source_wiki.id} migrated_wiki.id: #{wiki.id}"
      RedmineMerge::Mapper.add_wiki(source_wiki.id, wiki.id)

    end
  end
end