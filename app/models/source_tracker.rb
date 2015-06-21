
class SourceTracker < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'trackers'

  has_and_belongs_to_many :projects, :class_name => 'SourceProject', :join_table => 'projects_trackers', :foreign_key => 'tracker_id', :association_foreign_key => 'project_id'
  has_and_belongs_to_many :custom_fields, :class_name => 'SourceCustomField', :join_table => "custom_fields_trackers", :foreign_key => 'tracker_id', :association_foreign_key => 'custom_field_id'

  def self.find_target(source_tracker)
    return nil unless source_tracker
    fail "Expected SourceTracker got #{source_tracker.class}" unless source_tracker.is_a?(SourceTracker)
    Tracker.find_by_name(source_tracker.name)
  end

  def self.migrate_custom_fields(source_tracker, target_tracker)
    Array(source_tracker.custom_fields).each do |source_custom_field|
      target_custom_field = SourceCustomField.find_target(source_custom_field)
      if target_custom_field.nil?
        puts "    Skipping missing target field #{source_custom_field.name}"
        next
      end
      if target_tracker.custom_fields.include?(target_custom_field)
        puts "    Skipping existing custom field #{source_custom_field.name}"
        next
      end
      puts "    Adding custom field #{source_custom_field.name}"
      target_tracker.custom_fields << target_custom_field
    end
    target_tracker.save
  end

  def self.migrate
    all.each do |source_tracker|
      target_tracker = SourceTracker.find_target(source_tracker)
      if target_tracker
        puts "  Skipping existing tracker #{source_tracker.name}"
      else
        puts "  Migrating tracker #{source_tracker.name}"
        target_tracker = Tracker.create!(source_tracker.attributes)
      end
      migrate_custom_fields(source_tracker, target_tracker)
    end
  end
end
