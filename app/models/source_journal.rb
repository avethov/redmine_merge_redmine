class SourceJournal < ActiveRecord::Base
  include SecondDatabase
  set_table_name :journals

  belongs_to :journalized, :polymorphic => true
  belongs_to :issue, :class_name => 'SourceIssue', :foreign_key => :journalized_id
  # Added by KS
  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'
  
  def self.migrate
    all.each do |source_journals|

      journal = Journal.create!(source_journals.attributes) do |j|
        j.issue = Issue.find_by_subject(source_journals.issue.subject)
        # Added by KS
        j.user = User.find_by_login(source_jounrnals.user.login)
      end

      RedmineMerge::Mapper.add_journal(source_journals.id, journal.id)
    end
  end
end
