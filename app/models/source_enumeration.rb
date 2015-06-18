class SourceEnumeration < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'enumerations'

  ALLOWED_TYPES = %w(IssuePriority TimeEntryActivity DocumentCategory)

  belongs_to :project, class_name: 'SourceProject', foreign_key: 'project_id'

  def self.find_target(source_enum)
    return nil unless source_enum
    fail "Expected SourceEnumeration got #{source_enum.class}" unless source_enum.is_a?(SourceEnumeration)
    fail "Unknown enum type #{source_enum.type}" unless ALLOWED_TYPES.include?(source_enum.type)
    project = SourceProject.find_target(source_enum.project)
    conditions = { name: source_enum.name }
    conditions[:project_id] = project.id if project
    source_enum.type.constantize.where(conditions).first
  end

  def self.migrate_enum(type)
    klass = type.constantize
    where(type: type).each do |source_enum|
      if SourceEnumeration.find_target(source_enum)
        puts "  Skipping existing #{type} with name #{source_enum.name}"
        next
      end

      klass.create!(source_enum.attributes) do |i|
        i.project = SourceProject.find_target(source_enum.project)
      end
    end
  end

  def self.migrate_issue_priorities
    migrate_enum('IssuePriority')
  end

  def self.migrate_time_entry_activities
    migrate_enum('TimeEntryActivity')
  end

  def self.migrate_document_categories
    migrate_enum('DocumentCategory')
  end
end
