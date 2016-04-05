class SourceRbProjectSettings < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'rb_project_settings'

  belongs_to :project, class_name: 'SourceProject', foreign_key: 'project_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceRbProjectSettings got #{source.class}" unless source.is_a?(SourceRbProjectSettings)
    RbProjectSettings.where(
      project_id: SourceProject.find_target(source.project)
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)
	  
	  if !source.project
	    puts "  WARN Skipping backlog project settings, missing project"
	    next
	  end

      if target
        puts "  Skipping existing backlog project #{target.project.name} settings"
      else
        puts "  Migrating backlog project #{source.project.name} settings"
        target = RbProjectSettings.create!(source.attributes) do |s|
		  s.id = nil
          s.project = SourceProject.find_target(source.project)
        end
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
