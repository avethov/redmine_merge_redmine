class SourceTracker < ActiveRecord::Base
  include SecondDatabase
  set_table_name :trackers

  has_and_belongs_to_many :projects, :class_name => 'SourceProject', :join_table => 'projects_trackers', :foreign_key => 'tracker_id', :association_foreign_key => 'project_id'
  has_and_belongs_to_many :custom_fields, :class_name => 'SourceCustomField', :join_table => "custom_fields_trackers", :foreign_key => 'tracker_id', :association_foreign_key => 'custom_field_id'

  def self.migrate
    all.each do |source_tracker|
      # TODO - need to add custom_fields to any existing trackers
      next if Tracker.find_by_name(source_tracker.name)
      
      Tracker.create!(source_tracker.attributes) do |t|
        
        puts "handling custom_fields_trackers for tracker #{source_tracker.name}"        
        if source_tracker.custom_fields
          source_tracker.custom_fields.each do |source_custom_field|
            puts "source_custom_field name:  #{source_custom_field.name} id: #{source_custom_field.id}"
            merged_custom_field = IssueCustomField.find_by_name(source_custom_field.name)  
            if merged_custom_field
              puts "merged_custom_field name:  #{merged_custom_field.name} id: #{merged_custom_field.id}"
              t.custom_fields << merged_custom_field
              puts "After inserting merged_custom_field name =  #{merged_custom_field.name} id = #{merged_custom_field.id}"
            end
          end
        end        
        puts "Done with custom_fields for tracker #{t.name}"
      end
    end
  end
end
