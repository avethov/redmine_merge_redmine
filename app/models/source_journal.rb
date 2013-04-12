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