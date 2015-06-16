class SourceIssueRelation < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'issue_relations'

  belongs_to :issue_from, class_name: 'SourceIssue', foreign_key: 'issue_from_id'
  belongs_to :issue_to,   class_name: 'SourceIssue', foreign_key: 'issue_to_id'

  def self.find_target(source)
    return nil unless source
    IssueRelation.where(
      issue_from: SourceIssue.find_target(source.issue_from),
      issue_to:   SourceIssue.find_target(source.issue_to),
      relation_type: source.relation_type
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)
      if target
        puts "  Skipping existing relation: ##{target.issue_from.id} #{target.relation_type} ##{target.issue_to.id}"
        next
      end

      issue_from = SourceIssue.find_target(source.issue_from)
      issue_to   = SourceIssue.find_target(source.issue_to)

      puts "  Migrating relation: ##{issue_from.id} #{source.relation_type} ##{issue_to.id}"
      IssueRelation.create!(source.attributes) do |ir|
        ir.issue_from = issue_from
        ir.issue_to   = issue_to
      end
    end
  end
end
