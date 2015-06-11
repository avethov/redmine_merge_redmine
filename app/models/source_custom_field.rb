class SourceCustomField < ActiveRecord::Base
  include SecondDatabase
  set_table_name :custom_fields

  has_and_belongs_to_many :projects, :class_name => 'SourceProject', :join_table => 'custom_fields_projects', :foreign_key => 'custom_field_id', :association_foreign_key => 'project_id'
  has_and_belongs_to_many :trackers, :class_name => 'SourceTracker', :join_table => 'custom_fields_trackers', :foreign_key => 'custom_field_id', :association_foreign_key => 'tracker_id'

  def self.find_target(source_custom_field)
    return nil unless source_custom_field
    CustomField.find_by_name(source_custom_field.name)
  end

  def self.migrate
    all.each do |source_custom_field|
      if SourceCustomField.find_target(source_custom_field)
        puts "  Skipping existing custom field #{source_custom_field.name}"
        next
      end

      CustomField.create!(source_custom_field.attributes) do |cf|
        # Type must be set explicitly -- not included in the attributes
        cf.type = source_custom_field.type
      end
    end
  end
end
