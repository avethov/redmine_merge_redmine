
class SourceTracker < ActiveRecord::Base
  include SecondDatabase
  set_table_name :trackers

  has_and_belongs_to_many :projects, :class_name => 'SourceProject', :join_table => 'projects_trackers', :foreign_key => 'tracker_id', :association_foreign_key => 'project_id'
  has_and_belongs_to_many :custom_fields, :class_name => 'SourceCustomField', :join_table => "custom_fields_trackers", :foreign_key => 'tracker_id', :association_foreign_key => 'custom_field_id'

  def self.find_target(source_tracker)
    return nil unless source_tracker
    Tracker.find_by_name(source_tracker.name)
  end

  def self.migrate_tracker_custom_fields(target_tracker, source_fields)
    Array(source_fields).each do |source_field|
      target_field = SourceCustomField.find_target(source_field)
      if target_field.nil?
        puts "    Skipping missing target field #{source_field.name}"
        next
      end
      if target_tracker.custom_fields.include?(target_field)
        puts "    Skipping existing custom field #{source_field.name}"
        next
      end
      puts "    Adding custom field #{source_field.name}"
      target_tracker.custom_fields << target_field
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
        Tracker.create!(source_tracker.attributes)
      end
      migrate_tracker_custom_fields(source_tracker, target_tracker)
    end
  end
end
