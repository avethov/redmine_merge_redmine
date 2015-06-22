# We use TargetIssue so we can set `updated_on` and `created_on`
# manually, which would be overridden by Redmines original `Issue`
# model.
class TargetIssue < ActiveRecord::Base
  self.table_name = 'issues'

  belongs_to :project
  belongs_to :tracker
  belongs_to :status, :class_name => 'IssueStatus'
  belongs_to :author, :class_name => 'User'
  belongs_to :assigned_to, :class_name => 'Principal'
  belongs_to :fixed_version, :class_name => 'Version'
  belongs_to :priority, :class_name => 'IssuePriority'
  belongs_to :category, :class_name => 'IssueCategory'

  after_create do |record|
    unless record.root_id
      record.root_id = record.id
      record.save
    end
  end
end
