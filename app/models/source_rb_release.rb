class SourceRbRelease < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'releases'

  belongs_to :project, class_name: 'SourceProject', foreign_key: 'project_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceRbRelease got #{source.class}" unless source.is_a?(SourceRbRelease)
    RbRelease.where(
      project_id: SourceProject.find_target(source.project)
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)

	  if !source.project
	    puts "  WARN Skipping release #{source.name}, missing project"
		next
	  end

      if target
        puts "  Skipping existing release for project #{target.project.name}"
      else
        puts "  Migrating backlog release #{source.name}"
        target = RbRelease.create!(source.attributes) do |s|
		  s.id = nil
          s.project = SourceProject.find_target(source.project)
        end
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
