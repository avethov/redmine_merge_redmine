class SourceCustomValue < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "custom_values"

  belongs_to :custom_field, :class_name => 'SourceCustomField', :foreign_key => 'custom_field_id'
  belongs_to :customized, :polymorphic => true

  def self.migrate
    all.each do |source_custom_value|
      
      CustomValue.create!(source_custom_value.attributes) do |cv|
        cv.custom_field = CustomField.find_by_name(source_custom_value.custom_field.name)
        cv.customized = case source_custom_value.customized_type
                      when "Issue"
                        Issue.find RedmineMerge::Mapper.get_new_issue_id(source_custom_value.customized_id)
                      when "Document"
                        Document.find RedmineMerge::Mapper.get_new_document_id(source_custom_value.customized_id)
                      when "WikiPage"
                        WikiPage.find RedmineMerge::Mapper.get_new_wiki_page_id(source_custom_value.customized_id)
                      when "Project"
                        Project.find RedmineMerge::Mapper.get_new_project_id(source_custom_value.customized_id)
                      when "Version"
                        Version.find RedmineMerge::Mapper.get_new_version_id(source_custom_value.customized_id)
                      when "News"
                        News.find RedmineMerge::Mapper.get_new_news_id(source_custom_value.customized_id)
                      end
      end
    end
  end
end
