class SourceVersion < ActiveRecord::Base
  include SecondDatabase
  set_table_name :versions
  
  # KS - Added
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'

  def self.migrate
    all.each do |source_version|
      puts "source_version project name = #{source_version.project.name} version name = #{source_version.name}"
      # Added by KS to handle situation where entries may already be in database -- should only happen if you migrate twice
      version_temp = RedmineMerge::Mapper.find_id_by_property("Version", source_version.id)
      puts "Found matching version in merged db #{version_temp.name}" if version_temp
      
#      next if !RedmineMerge::Mapper.find_id_by_property("Version", source_version.id)
#      next if (Project.find_by_name(source_version.project.name) && 
#      next if Project.find_by_identifier(source_project.identifier)
      puts "Migrating source_version project name = #{source_version.project.name} version name = #{source_version.name}"

      version = Version.create!(source_version.attributes) do |v|
        v.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_version.project_id))
      end

      RedmineMerge::Mapper.add_version(source_version.id, version.id)
    end
  end
end
