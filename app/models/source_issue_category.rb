class SourceIssueCategory < ActiveRecord::Base
  include SecondDatabase
  set_table_name :issue_categories

  # KS - logic here seems flawed - they only create a new record if the category_name and "source" project_id are not 
  # in the database.  However, it seems like the mapped project id should be found and then the check done.  Also, I don't see the find_by_name_and_project_id method anywhere -- is it obsolete?
  def self.migrate
    all.each do |source_issue_category|
      next if IssueCategory.find_by_name_and_project_id(source_issue_category.name, source_issue_category.project_id)

      IssueCategory.create!(source_issue_category.attributes) do |ic|
        ic.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_issue_category.project_id))
      end
    end
  end
end
