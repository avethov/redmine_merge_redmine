# Created by Ken Sperow -- ideally there would be a model to use in Redmine but I don't see one
#            This table is written to by the inner class in wiki_content.rb (WikiContent::Version)
#

class WikiContentVersions < ActiveRecord::Base
  self.table_name = "wiki_content_versions"

end