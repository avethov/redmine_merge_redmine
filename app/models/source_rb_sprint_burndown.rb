require 'date'
require 'yaml'

class SourceRbSprintBurndown < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'rb_sprint_burndown'

  belongs_to :version, class_name: 'SourceVersion', foreign_key: 'version_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceRbSprintBurndown got #{source.class}" unless source.is_a?(SourceRbSprintBurndown)
    RbSprintBurndown.where(
      version_id: SourceVersion.find_target(source.version)
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)

	  if !source.version
	  	puts "  WARN Skipping backlog sprint burndown id #{source.id}, missing version"
	    next
	  end

      if target
        puts "  Skipping existing backlog sprint #{target.version.name} burndown"
      else
        puts "  Migrating backlog sprint #{source.version.name} burndown"

		attributes = source.attributes.dup.except('stories', 'burndown')
        target = RbSprintBurndown.create!(attributes) do |s|
		  s.id = nil
          s.version = SourceVersion.find_target(source.version)
		  s.stories = YAML.load(source.stories)
		  s.burndown = YAML.load(source.burndown)
		  s.created_at = source.created_at
		  s.updated_at = source.updated_at
        end
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
