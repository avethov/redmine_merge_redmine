class SourceWikiContent < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'wiki_contents'

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'
  belongs_to :page, :class_name => 'SourceWikiPage', :foreign_key => 'page_id'

  def self.find_target(source_wiki_content)
    return nil unless source_wiki_content
    page = SourceWikiPage.find_target(source_wiki_content.page)
    WikiContent.find_by_id(RedmineMerge::Mapper.get_new_wiki_content_id(source_wiki_content.id)) ||
      WikiContent.find_by_page_id(page.id)
  end

  def self.migrate
    all.each do |source_wiki_content|
      target_wiki_content = SourceWikiContent.find_target(source_wiki_content)
      if target_wiki_content
        puts "  Skipping existing wiki content for page #{source_wiki_content.page.title} by #{source_wiki_content.author}"
      else
        puts <<LOG
  Migrating wiki content for page #{source_wiki_content.page.title}
    id: #{source_wiki_content.author_id}
    author: #{source_wiki_content.author} (#{source_wiki_content.author.id})
    version: #{source_wiki_content.version}
LOG
        target_wiki_content = WikiContent.create!(source_wiki_content.attributes) do |wc|
          wc.page = SourceWikiPage.find_target(source_wiki_content.page)
          wc.author = SourceUser.find_target(source_wiki_content.author)
        end
      end

      RedmineMerge::Mapper.add_wiki_content(source_wiki_content.id, target_wiki_content.id)
    end
  end
end
