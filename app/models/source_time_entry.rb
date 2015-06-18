class SourceTimeEntry < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'time_entries'

  belongs_to :user,     class_name: 'SourceUser',        foreign_key: 'user_id'
  belongs_to :project,  class_name: 'SourceProject',     foreign_key: 'project_id'
  belongs_to :issue,    class_name: 'SourceIssue',       foreign_key: 'issue_id'
  belongs_to :activity, class_name: 'SourceEnumeration', foreign_key: 'activity_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceTimeEntry got #{source.class}" unless source.is_a?(SourceTimeEntry)
    TimeEntry.where(
      user:       SourceUser.find_target(source.user),
      project:    SourceProject.find_target(source.project),
      activity:   SourceEnumeration.find_target(source.activity),
      issue:      SourceIssue.find_target(source.issue),
      hours:      source.hours,
      spent_on:   source.spent_on,
      created_on: source.created_on
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)
      if target
        puts "  Skipping existing time entry: #{source.hours}h by #{source.user}"
        next
      end

      puts "  Migrating time entry: #{source.hours}h by #{source.user}"
      TimeEntry.create!(source.attributes) do |te|
        te.user     = SourceUser.find_target(source.user)
        te.project  = SourceProject.find_target(source.project)
        te.activity = SourceEnumeration.find_target(source.activity)
        te.issue    = SourceIssue.find_target(source.issue)
        te.hours    = 0.01 if te.hours == 0
      end
    end
  end
end
