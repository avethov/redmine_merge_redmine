class SourceTimeEntry < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'time_entries'

  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'
  belongs_to :issue, :class_name => 'SourceIssue', :foreign_key => 'issue_id'
  belongs_to :activity, :class_name => 'SourceEnumeration', :foreign_key => 'activity_id'
  

  def self.migrate
    all.each do |source_time_entry|
      
      puts "TimeEntry id: #{source_time_entry.id}"
      puts "  hours: #{source_time_entry.hours}"
      
      # Validation does not allow a value of 0 for hours - Hack to set it to a very low value
      if source_time_entry.hours == 0
        source_time_entry.hours = 0.01
      end
      
      time_entry = TimeEntry.create!(source_time_entry.attributes) do |te|
      
        te.user = User.find_by_login(source_time_entry.user.login)
        te.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_time_entry.project_id))
        te.activity = TimeEntryActivity.find_by_name(source_time_entry.activity.name)

        # optional 
        te.issue = Issue.find_by_id(RedmineMerge::Mapper.get_new_issue_id(source_time_entry.issue.id)) if source_time_entry.issue_id
          
      end
      puts "  merged id: #{time_entry.id}"
    end
  end
end
