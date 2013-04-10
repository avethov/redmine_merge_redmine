class SourceProject < ActiveRecord::Base
  include SecondDatabase
  set_table_name :projects

  has_many :enabled_modules, :class_name => 'SourceEnabledModule', :foreign_key => 'project_id'
  has_and_belongs_to_many :trackers, :class_name => 'SourceTracker', :join_table => 'projects_trackers', :foreign_key => 'project_id', :association_foreign_key => 'tracker_id'
  has_and_belongs_to_many :custom_fields, :class_name => 'SourceCustomField', :join_table => "custom_fields_projects", :foreign_key => 'project_id', :association_foreign_key => 'custom_field_id'

      
  def self.migrate
    all(:order => 'lft ASC').each do |source_project|
      next if Project.find_by_name(source_project.name)
      next if Project.find_by_identifier(source_project.identifier)
      
      # KS - additions to try to prevent the errors when calling create()
      # Unauthorized assignment to lft: it's an internal field handled by acts_as_nested_set code, use move_to_* methods instead.
  
      attributes = source_project.attributes.dup.except('trackers', 'parent_id', 'lft', 'rgt')
          
      project = Project.create!(attributes) do |p|
        p.status = source_project.status
        if source_project.enabled_modules
          p.enabled_module_names = source_project.enabled_modules.collect(&:name)
        end
        
        puts "handling project trackers for project #{p.name}"
        # KS - for some reason the project trackers get initialized with entries for all trackers -- need to clear out
        p.trackers = []
#        puts "After emptying out p.trackers for project, project name = #{p.name} trackers = #{p.trackers}"        
        
        if source_project.trackers
          source_project.trackers.each do |source_tracker|
            merged_tracker = Tracker.find_by_name(source_tracker.name)
#            puts "merged_tracker name =  #{merged_tracker.name} id = #{merged_tracker.id}"
            p.trackers << merged_tracker if merged_tracker
#            puts "After inserting merged_tracker name =  #{merged_tracker.name} id = #{merged_tracker.id}" if merged_tracker
          end
        end
        
        # Deal with custom_fields
        puts "handling custom_fields_trackers for tracker #{source_project.name}"        
        if source_project.custom_fields
          source_project.custom_fields.each do |source_custom_field|
            puts "source_custom_field name:  #{source_custom_field.name} id: #{source_custom_field.id}"
            merged_custom_field = IssueCustomField.find_by_name(source_custom_field.name)  
            if merged_custom_field
              puts "merged_custom_field name:  #{merged_custom_field.name} id: #{merged_custom_field.id}"
              p.issue_custom_fields << merged_custom_field
              puts "After inserting merged_custom_field name =  #{merged_custom_field.name} id = #{merged_custom_field.id}"
            end
          end
        end        
        puts "Done with custom_fields for tracker #{p.name}"
                
      end
      
      # Parent/child projects
      if source_project.parent_id
        project.set_parent!(Project.find_by_id(RedmineMerge::Mapper.get_new_project_id(source_project.parent_id)))
      end
      
      RedmineMerge::Mapper.add_project(source_project.id, project.id)
    end
  end
end
