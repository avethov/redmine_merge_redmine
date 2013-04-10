class SourceWikiContent < ActiveRecord::Base
  include SecondDatabase
  set_table_name :wiki_contents

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'

  def self.migrate
    all.each do |source_wiki_content|
      
      puts "author login: #{source_wiki_content.author.login}  id: #{source_wiki_content.author_id}  author.id: #{source_wiki_content.author.id}"

      wiki_content = WikiContent.create!(source_wiki_content.attributes) do |wc|
        wc.page = WikiPage.find(RedmineMerge::Mapper.get_new_wiki_page_id(source_wiki_content.page_id))
        wc.author = User.find_by_login(source_wiki_content.author.login)
      end
      
      # Needed so the wiki_contents_versions table can be migrated
      RedmineMerge::Mapper.add_wiki_content(source_wiki_content.id, wiki_content.id)
    end
  end
end
