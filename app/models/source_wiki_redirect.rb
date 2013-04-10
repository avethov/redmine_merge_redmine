# Added by Ken Sperow

class SourceWikiRedirect < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "wiki_redirects"

  def self.migrate
    all.each do |source_wiki_redirect|
      
      wiki_page = WikiRedirect.create!(source_wiki_redirect.attributes) do |wr|
        wr.wiki = Wiki.find(RedmineMerge::Mapper.get_new_wiki_id(source_wiki_redirect.wiki_id))
      end
    end
  end
end