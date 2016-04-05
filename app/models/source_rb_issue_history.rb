require 'yaml'
require 'pp'

class SourceRbIssueHistory < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'rb_issue_history'

  belongs_to :issue, class_name: 'SourceIssue', foreign_key: 'issue_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceRbIssueHistory got #{source.class}" unless source.is_a?(SourceRbIssueHistory)
    RbIssueHistory.where(
      issue_id: SourceIssue.find_target(source.issue)
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)

	  if !source.issue
	    puts "  WARN Skipping existing backlog issue history id #{source.id}, missing issue id #{source.issue_id}"
	    next
	  end

      if target
        puts "  Skipping existing backlog issue #{target.issue.subject} history"
      else
        puts "  Migrating backlog issue #{source.issue.subject} history"
		issue_target = SourceIssue.find_target(source.issue)
        target = RbIssueHistory.create!(issue: issue_target) do |s|
		  s.id = nil
		  s.history = YAML.load(source.history)
        end
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
