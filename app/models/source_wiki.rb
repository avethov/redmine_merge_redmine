class SourceWiki < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "wikis"

  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'

  def self.find_target(source_wiki)
    return nil unless source_wiki
    project = SourceProject.find_target(source_wiki.project)
    Wiki.find_by_id(RedmineMerge::Mapper.get_new_wiki_id(source_wiki.id)) ||
      Wiki.find_by_project_id(project.id)
  end

  def self.migrate
    all.each do |source_wiki|
      target_wiki = SourceWiki.find_target(source_wiki)

      if target_wiki
        puts "  Skipping existing wiki for project #{target_wiki.project.name}"
      else
        puts "  Migrating wiki for project #{source_wiki.project.name}"
        target_wiki = Wiki.create!(source_wiki.attributes) do |w|
          w.project = SourceProject.find_target(source_wiki.project)
        end
      end

      RedmineMerge::Mapper.add_wiki(source_wiki.id, target_wiki.id)
    end
  end
end
