class SourceIssue < ActiveRecord::Base
  include SecondDatabase
  set_table_name :issues

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'
  belongs_to :assigned_to, :class_name => 'SourceUser', :foreign_key => 'assigned_to_id'
  belongs_to :status, :class_name => 'SourceIssueStatus', :foreign_key => 'status_id'
  belongs_to :tracker, :class_name => 'SourceTracker', :foreign_key => 'tracker_id'
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'
  belongs_to :priority, :class_name => 'SourceEnumeration', :foreign_key => 'priority_id'
  belongs_to :category, :class_name => 'SourceIssueCategory', :foreign_key => 'category_id'
  # Added by KS
  belongs_to :fixed_version, :class_name => 'SourceVersion', :foreign_key => 'fixed_version_id'
  
  
  def self.migrate
    
    puts "Print out the trackers -- trying to figure out if they are all loaded"
    Tracker.find do |t|
      puts "Tracker id = #{t.id} name = #{t.name}"
    end
    
    
    
    all.each do |source_issue|
      
      attributes = source_issue.attributes.dup.except('tracker', 'parent_id', 'lft', 'rgt')
#      attributes = source_issue.attributes.dup.except('parent_id', 'lft', 'rgt')
      source_issue.author_id = User.find_by_login(source_issue.author.login)
      source_issue.project_id = RedmineMerge::Mapper.get_new_project_id(source_issue.project.id)
      source_issue.assigned_to_id = User.find_by_login(source_issue.assigned_to.login) if source_issue.assigned_to
#      source_issue.tracker_id = Tracker.find_by_name(source_issue.tracker.name)

#      puts "Attempt to migrate #{source_issue.id}, #{source_issue.subject} tracker = #{source_issue.tracker.name}"
      puts "Attempt to migrate #{source_issue.id}, #{source_issue.subject} tracker = #{source_issue.tracker.name}"
      
      issue = Issue.create!(attributes) do |i|
#      issue = Issue.create!(source_issue.attributes) do |i|
#        i.project = Project.find_by_name(source_issue.project.name)
#        i.author = User.find_by_login(source_issue.author.login)
#        i.assigned_to = User.find_by_login(source_issue.assigned_to.login) if source_issue.assigned_to
#        puts "Created #{i.id}, #{i.subject}, tracker = #{i.tracker.name}"

        i.status = IssueStatus.find_by_name(source_issue.status.name)
        i.tracker = Tracker.find_by_name(source_issue.tracker.name)
#        i.tracker_id = Tracker.find_by_name(source_issue.tracker.name)
        i.priority = IssuePriority.find_by_name(source_issue.priority.name)
        i.category = IssueCategory.find_by_name(source_issue.category.name) if source_issue.category
        # Added by KS -- Need to confirm that this method exists
        i.fixed_version = Version.find_by_name_and_project_id(source_issue.category.name, i.project.id) if source_issue.fixed_version
        puts "Created #{i.id}, #{i.subject}, tracker = #{i.tracker.name}, id = #{i.tracker.id}"

      end
      
      RedmineMerge::Mapper.add_issue(source_issue.id, issue.id)
    end
  end
end
