class SourceIssueStatus < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'issue_statuses'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceIssueStatus got #{source.class}" unless source.is_a?(SourceIssueStatus)
    IssueStatus.find_by_name(source.name)
  end

  def self.migrate
    all.each do |source_issue_status|
      if SourceIssueStatus.find_target(source_issue_status)
        puts "  Skipping existing issue status #{source_issue_status.name}"
        next
      end

      IssueStatus.create!(source_issue_status.attributes)
    end
  end
end
