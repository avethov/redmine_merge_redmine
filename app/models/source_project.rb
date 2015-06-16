class SourceProject < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'projects'

  has_many :enabled_modules, class_name: 'SourceEnabledModule', foreign_key: 'project_id'
  has_and_belongs_to_many :trackers, class_name: 'SourceTracker', join_table: 'projects_trackers', foreign_key: 'project_id', association_foreign_key: 'tracker_id'
  has_and_belongs_to_many :custom_fields, class_name: 'SourceCustomField', join_table: 'custom_fields_projects', foreign_key: 'project_id', association_foreign_key: 'custom_field_id'
  belongs_to :parent, class_name: 'SourceProject'

  def self.find_target(source_project)
    return nil unless source_project
    Project.find_by_id(RedmineMerge::Mapper.target_id(source_project)) ||
      Project.find_by_name(source_project.name) ||
      Project.find_by_identifier(source_project.identifier)
  end

  def self.create_target(source_project)
    # KS - additions to try to prevent the errors when calling create()
    # Unauthorized assignment to lft: it's an internal field handled
    # by acts_as_nested_set code, use move_to_* methods instead.

    attributes = source_project.attributes.dup.except('trackers', 'parent_id', 'lft', 'rgt')
    project = Project.create!(attributes) do |p|
      p.status = source_project.status
      if source_project.enabled_modules
        p.enabled_module_names = source_project.enabled_modules.collect(&:name)
      end

      # KS - for some reason the project trackers get initialized with
      # entries for all trackers -- need to clear out
      p.trackers = []
      Array(source_project.trackers).each do |source_tracker|
        target_tracker = SourceTracker.find_target(source_tracker)
        p.trackers << target_tracker if target_tracker
      end

      # Take over custom fields for the new target project
      Array(source_project.custom_fields).each do |source_custom_field|
        target_custom_field = SourceCustomField.find_target(source_custom_field)
        p.issue_custom_fields << target_custom_field if target_custom_field
      end
    end

    if source_project.parent
      project.set_parent!(SourceProject.find_target(source_project.parent))
    end

    project
  end

  def self.migrate
    order(lft: :asc).each do |source_project|
      target_project = SourceProject.find_target(source_project)

      if target_project
        puts "  Skipping existing project with #{target_project.name} (#{target_project.id}: #{target_project.identifier})"
      else
        puts "  Migrating project #{source_project.name} (#{source_project.id}: #{source_project.identifier})"
        target_project = create_target(source_project)
        puts "    Target project #{target_project.name} (#{target_project.id}: #{target_project.identifier})"
      end

      RedmineMerge::Mapper.map(source_project, target_project)
    end
  end
end
