class SourceWikiContentVersions < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "wiki_content_versions"

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'

  def self.migrate
    all.each do |source_wiki_content_version|
      
      puts "author login: #{source_wiki_content_version.author.login}  id: #{source_wiki_content_version.author_id}  author.id: #{source_wiki_content_version.author.id}"
      
      WikiContentVersions.create!(source_wiki_content_version.attributes) do |wcv|
        wcv.page_id = RedmineMerge::Mapper.get_new_wiki_page_id(source_wiki_content_version.page_id)
        wcv.author_id = User.find_by_login(source_wiki_content_version.author.login).id
        wcv.wiki_content_id = RedmineMerge::Mapper.get_new_wiki_content_id(source_wiki_content_version.wiki_content_id)
      end
    end
  end
end