class SourceWiki < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'wikis'

  belongs_to :project, class_name: 'SourceProject', foreign_key: 'project_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceWiki got #{source.class}" unless source.is_a?(SourceWiki)
    Wiki.find_by_id(RedmineMerge::Mapper.target_id(source)) ||
      Wiki.where(
        project_id: SourceProject.find_target(source.project)
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)

      if target
        puts "  Skipping existing wiki for project #{target.project.name}"
      else
        puts "  Migrating wiki for project #{source.project.name}"
        target = Wiki.create!(source.attributes) do |w|
          w.project = SourceProject.find_target(source.project)
        end
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
