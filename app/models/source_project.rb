class SourceProject < ActiveRecord::Base
  include SecondDatabase
  set_table_name :projects

  has_many :enabled_modules, :class_name => 'SourceEnabledModule', :foreign_key => 'project_id'
  has_and_belongs_to_many :trackers, :class_name => 'SourceTracker', :join_table => 'projects_trackers', :foreign_key => 'project_id', :association_foreign_key => 'tracker_id'
  
      
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
        
        puts "Done with trackers for project #{p.name}"
        
      end
      
      # Parent/child projects
      if source_project.parent_id
        project.set_parent!(Project.find_by_id(RedmineMerge::Mapper.get_new_project_id(source_project.parent_id)))
      end
      
      RedmineMerge::Mapper.add_project(source_project.id, project.id)
    end
  end
end
