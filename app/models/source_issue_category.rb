class SourceIssueCategory < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'issue_categories'

  belongs_to :project, class_name: 'SourceProject', foreign_key: 'project_id'

  def self.find_target(source)
    return nil unless source
    IssueCategory.where(
      name: source.name,
      project_id: SourceProject.find_target(source.project)
    ).first
  end

  def self.migrate
    all.each do |source|
      target_issue_category = SourceIssueCategory.find_target(source)

      if target_issue_category
        puts "  Skipping existing issue category #{source.name} for project #{source.project.name}"
        next
      end

      puts "  Migrating issue category #{source.name} for project #{source.project.name}"
      IssueCategory.create!(source.attributes) do |ic|
        ic.project = SourceProject.find_target(source.project)
      end
    end
  end
end
