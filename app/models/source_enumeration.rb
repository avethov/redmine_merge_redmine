class SourceEnumeration < ActiveRecord::Base
  include SecondDatabase
  set_table_name :enumerations

  # KS TODO - need to handle issue project_id and parent_id
  def self.migrate_issue_priorities
    all(:conditions => {:type => "IssuePriority"}) .each do |source_issue_priority|
      next if IssuePriority.find_by_name(source_issue_priority.name)
      
      # Added by KS
      project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_issue_priority.project_id)) if source_issue_priority.project_id

      IssuePriority.create!(source_issue_priority.attributes) do |i|
        i.project = project if project
      end
    end
  end

  def self.migrate_time_entry_activities
    all(:conditions => {:type => "TimeEntryActivity"}) .each do |source_activity|
      next if TimeEntryActivity.find_by_name(source_activity.name)

      # Added by KS
      project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_activity.project_id)) if source_activity.project_id
      
      TimeEntryActivity.create!(source_activity.attributes) do |a|
        a.project = project
      end
    end
  end

  def self.migrate_document_categories
    all(:conditions => {:type => "DocumentCategory"}) .each do |source_document_category|
      next if DocumentCategory.find_by_name(source_document_category.name)

      # Added by KS
      project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_document_category.project_id)) if source_document_category.project_id

      DocumentCategory.create!(source_document_category.attributes)  do |d|
        d.project = project if project
      end
    end
  end

end
