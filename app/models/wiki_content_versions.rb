# Created by Ken Sperow -- ideally there would be a model to use in Redmine but I don't see one
#            This table is written to by the inner class in wiki_content.rb (WikiContent::Version)
#

class WikiContentVersions < ActiveRecord::Base
  self.table_name = "wiki_content_versions"

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :page, :class_name => 'WikiPage', :foreign_key => 'page_id'
  belongs_to :wiki_content, :class_name => 'WikiContent', :foreign_key => 'wiki_content_id'
end
