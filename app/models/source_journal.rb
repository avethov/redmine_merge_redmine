class SourceJournal < ActiveRecord::Base
  include SecondDatabase
  set_table_name :journals

  belongs_to :journalized, :polymorphic => true
  belongs_to :issue, :class_name => 'SourceIssue', :foreign_key => :journalized_id
  # Added by KS
  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'
  
  def self.migrate
    all.each do |source_journals|
            
      # It is possible that the issue has been deleted -- don't insert journal entries associated
      #  with deleted issues
      if source_journals.issue

        # Add logic to replace any #1234 with the new issue number
        # - Pull out the matching issue number string from the "Notes"
        # - Determine if the issue number matches a source issue number, if so get the merged issue number
        # - Replace the source issue number with the merged issue number in the "notes" column
        if source_journals.notes
          issue_strings = source_journals.notes.scan /#[\d]+/      
          issue_strings.each do |issue_string| 
            puts "Matched issue string: #{issue_string}  journalalized_id: #{source_journals.issue.id}"
            issue_number = issue_string.gsub(/#/, "")
            merged_issue_number = RedmineMerge::Mapper.get_new_issue_id(issue_number.to_i)
            if (merged_issue_number)
              puts "  Replacing: '#{issue_string}' with: '##{merged_issue_number}'"
              source_journals.notes = source_journals.notes.gsub("#{issue_string}","##{merged_issue_number}")          
            end
          end      
        end

        journal = Journal.create!(source_journals.attributes) do |j|
          j.issue = Issue.find(RedmineMerge::Mapper.get_new_issue_id(source_journals.issue.id))
          # Added by KS
          j.user = User.find_by_login(source_journals.user.login)
        end
        RedmineMerge::Mapper.add_journal(source_journals.id, journal.id)
      end
    end
  end
end