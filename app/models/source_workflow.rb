class SourceWorkflow < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "workflows"
  
#  belongs_to :role, :class_name => 'SourceRole', :foreign_key => 'role_id'
#  belongs_to :tracker, :class_name => 'SourceTracker', :foreign_key => 'tracker_id'
#  belongs_to :old_status, :class_name => 'SourceIssueStatus', :foreign_key => 'old_status_id'
#  belongs_to :new_status, :class_name => 'SourceIssueStatus', :foreign_key => 'new_status_id'
  
  def self.migrate
#    puts "Print out the Source IssueStatus"
#    SourceIssueStatus.find do |sis|
#      puts "SourceIssueStatus id = #{sis.id} name = #{sis.name}"
#    end
#    
#    puts "Print out the merged IssueStatus"
#    IssueStatus.find do |i|
#      puts "IssueStatus id = #{i.id} name = #{i.name}"
#    end
#
#    puts "Print out the source Roles #{SourceRole.count}"
#    SourceRole.find do |sr|
#      puts "Role id = #{sr.id} name = #{sr.name}"
#    end
#
#    puts "Print out the merged Roles #{Role.count}"
#    Role.find do |r|
#      puts "Role id = #{r.id} name = #{r.name}"
#    end
#    
    all.each do |source_workflow|
    
          old_status = SourceIssueStatus.find_by_id(source_workflow.old_status_id)
    
          new_status = SourceIssueStatus.find_by_id(source_workflow.new_status_id)
    
          role = SourceRole.find_by_id(source_workflow.role_id)
    
          tracker = SourceTracker.find_by_id(source_workflow.tracker_id)
    
          WorkflowRule.create!(source_workflow.attributes) do |w|
            w.old_status = IssueStatus.find_by_name(old_status.name)
            w.new_status = IssueStatus.find_by_name(new_status.name)
            w.role = Role.find_by_name(role.name)
            w.tracker = Tracker.find_by_name(tracker.name)
            w.type = "WorkflowTransition"
          end
    
        end
    
      end
    
    end
