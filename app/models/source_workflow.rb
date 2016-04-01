class SourceWorkflow < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'workflows'

  belongs_to :role,       class_name: 'SourceRole'
  belongs_to :tracker,    class_name: 'SourceTracker'
  belongs_to :old_status, class_name: 'SourceIssueStatus'
  belongs_to :new_status, class_name: 'SourceIssueStatus'

  def self.find_target(source_workflow)
    return nil unless source_workflow
    fail "Expected SourceWorkflow got #{source_workflow.class}" unless source_workflow.is_a?(SourceWorkflow)
    WorkflowRule.where(
      old_status_id: SourceIssueStatus.find_target(source_workflow.old_status),
      new_status_id: SourceIssueStatus.find_target(source_workflow.new_status),
      role_id:       SourceRole.find_target(source_workflow.role),
      tracker_id:    SourceTracker.find_target(source_workflow.tracker)
    ).first
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
        w.type       = source_workflow.type
      end

      migrated += 1
    end

    puts "  #{skipped} skipped existing workflow rules"
    puts "  #{migrated} migrated workflow rules"
  end
end
