class SourceWorkflow < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'workflows'

  belongs_to :role, :class_name => 'SourceRole', :foreign_key => 'role_id'
  belongs_to :tracker, :class_name => 'SourceTracker', :foreign_key => 'tracker_id'
  belongs_to :old_status, :class_name => 'SourceIssueStatus', :foreign_key => 'old_status_id'
  belongs_to :new_status, :class_name => 'SourceIssueStatus', :foreign_key => 'new_status_id'

  def self.find_target(source_workflow)
    target_old_status = SourceIssueStatus.find_target(source_workflow.old_status)
    target_new_status = SourceIssueStatus.find_target(source_workflow.new_status)
    target_role       = SourceRole.find_target(source_workflow.role)
    target_tracker    = SourceTracker.find_target(source_workflow.tracker)

    WorkflowRule.first(:conditions => {
                         old_status_id: target_old_status.id,
                         new_status_id: target_new_status.id,
                         role_id:       target_role.id,
                         tracker_id:    target_tracker.id
                       })
  end

  def self.migrate
    migrated = 0
    skipped  = 0
    all.each do |source_workflow|
      if SourceWorkflow.find_target(source_workflow)
        skipped += 1
        next
      end

      WorkflowRule.create!(source_workflow.attributes) do |w|
        w.old_status = SourceIssueStatus.find_target(source_workflow.old_status)
        w.new_status = SourceIssueStatus.find_target(source_workflow.new_status)
        w.role       = SourceRole.find_target(source_workflow.role)
        w.tracker    = SourceTracker.find_target(source_workflow.tracker)
        w.type = 'WorkflowTransition'
      end

      migrated += 1
    end

    puts "  #{skipped} skipped existing workflow rules"
    puts "  #{migrated} migrated workflow rules"
  end
end
