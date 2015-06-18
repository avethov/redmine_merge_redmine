class SourceCustomField < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'custom_fields'

  has_and_belongs_to_many :projects, class_name: 'SourceProject', join_table: 'custom_fields_projects', foreign_key: 'custom_field_id', association_foreign_key: 'project_id'
  has_and_belongs_to_many :trackers, class_name: 'SourceTracker', join_table: 'custom_fields_trackers', foreign_key: 'custom_field_id', association_foreign_key: 'tracker_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceCustomField got #{source.class}" unless source.is_a?(SourceCustomField)
    CustomField.find_by_name(source.name)
  end

  def self.migrate
    all.each do |source|
      if SourceCustomField.find_target(source)
        puts "  Skipping existing custom field #{source.name}"
        next
      end

      CustomField.create!(source.attributes) do |cf|
        # Type must be set explicitly -- not included in the attributes
        cf.type = source.type
      end
    end
  end
end
