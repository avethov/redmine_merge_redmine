class SourceVersion < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'versions'

  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'

  def self.find_target(source_version)
    return nil unless source_version
    Version.find_by_id(RedmineMerge::Mapper.get_new_version_id(source_version.id)) ||
      Version.first(:conditions => {
                      :name => source_version.name,
                      :project_id => SourceProject.find_target(source_version.project).id
                    })
  end

  def self.migrate
    all.each do |source_version|
      target_version = SourceVersion.find_target(source_version)

      if target_version
        puts "  Skipping existing version #{source_version.name}"
      else
        puts <<LOG
  Migrating version
    project: #{source_version.project.name}
    version: #{source_version.name}
LOG
        target_version = Version.create!(source_version.attributes) do |v|
          v.project = SourceProject.find_target(source_version.project)
        end
      end

      RedmineMerge::Mapper.add_version(source_version.id, target_version.id)
    end
  end
end
