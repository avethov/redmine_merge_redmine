class SourceCustomField < ActiveRecord::Base
  include SecondDatabase
  set_table_name :custom_fields
  
  # custom_fields_projects migrated as part of SourceProjects
  has_and_belongs_to_many :projects, :class_name => 'SourceProject', :join_table => 'custom_fields_projects', :foreign_key => 'custom_field_id', :association_foreign_key => 'project_id'
  # custom_fields_trackers migrated as part of SourceTraker
  has_and_belongs_to_many :trackers, :class_name => 'SourceTracker', :join_table => 'custom_fields_trackers', :foreign_key => 'custom_field_id', :association_foreign_key => 'tracker_id'


  def self.migrate
    all.each do |source_custom_field|
      next if CustomField.find_by_name(source_custom_field.name)
      
      CustomField.create!(source_custom_field.attributes) do |cf|
        # Type must be set -- not included in the attributes
        cf.type = source_custom_field.type
      end
    end
  end
end
