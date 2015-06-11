class SourceIssueCategory < ActiveRecord::Base
  include SecondDatabase
  set_table_name :issue_categories

  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'

  def self.find_target(source_issue_category)
    project = SourceProject.find_target(source_issue_category.project)
    IssueCategory.find_by_name_and_project_id(source_issue_category.name, project)
  end

  def self.migrate
    all.each do |source_issue_category|
      target_issue_category = SourceIssueCategory.find_target(source_issue_category)

      if target_issue_category
        puts "  Skipping existing issue category #{source_issue_category.name} for project #{source_issue_category.project.name}"
        next
      end

      puts "  Migrating issue category #{source_issue_category.name} for project #{source_issue_category.project.name}"
      IssueCategory.create!(source_issue_category.attributes) do |ic|
        ic.project = SourceProject.find_target(source_issue_category.project)
      end
    end
  end
end
