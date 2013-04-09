class SourceWorkflow < ActiveRecord::Base
  include SecondDatabase
  set_table_name :workflows

#  belongs_to :role22, :class_name => 'SourceRole', :foreign_key => 'role_id'
#  belongs_to :role, :class_name => 'SourceRole', :foreign_key => 'role_id'
#  belongs_to :tracker, :class_name => 'SourceTracker', :foreign_key => 'tracker_id'
#  belongs_to :old_status, :class_name => 'SourceIssueStatus', :foreign_key => 'old_status_id'
#  belongs_to :new_status, :class_name => 'SourceIssueStatus', :foreign_key => 'new_status_id'
  
  def self.migrate

    puts "Print out the Source IssueStatus"
    SourceIssueStatus.find do |sis|
      puts "SourceIssueStatus id = #{sis.id} name = #{sis.name}"
    end
    
    puts "Print out the merged IssueStatus"
    IssueStatus.find do |i|
      puts "IssueStatus id = #{i.id} name = #{i.name}"
    end

    puts "Print out the source Roles #{SourceRole.count}"
    SourceRole.find do |sr|
      puts "Role id = #{sr.id} name = #{sr.name}"
    end

    puts "Print out the merged Roles #{Role.count}"
    Role.find do |r|
      puts "Role id = #{r.id} name = #{r.name}"
    end

    all.each do |source_workflow|    

      puts "attributes: #{source_workflow.attributes}"
      source_workflow.attributes.each do |a|
        puts "attribute: #{a}"
      end
      
            
      puts "SouceWorkflow: #{source_workflow.id} role_id: #{source_workflow.role_id}"
#      puts "Role id: #{source_workflow.role22.id} name: #{source_workflow.role22.name} "
      puts "Role id: #{source_workflow.role.id} name: #{source_workflow.role.name} "
      puts "Tracker id: #{source_workflow.tracker.id} name: #{source_workflow.tracker.name} "
      puts "Migrating workflows old_status_id = #{source_workflow.old_status.id} old_status name = #{source_workflow.old_status.name}"
      puts "new_status_id = #{source_workflow.new_status.id}"
      puts "new_status name = #{source_workflow.new_status.name}"
      
      WorkflowRule.create!(source_workflow.attributes) do |w|
        w.tracker = Tracker.find_by_name(source_workflow.tracker.name)
        w.old_status = IssueStatus.find_by_name(source_workflow.old_status.name)
        puts "Merged workflow old_status = #{w.old_status.name}"
        w.new_status = IssueStatus.find_by_name(source_workflow.new_status.name)
        puts "Merged workflow new_status = #{w.new_status.name}"
        w.role = Role.find_by_name(source_workflow.role.name)
      end
      
    end
  end
end
