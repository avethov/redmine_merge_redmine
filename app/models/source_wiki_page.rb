class SourceWikiPage < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'wiki_pages'

  belongs_to :wiki, :class_name => 'SourceWiki', :foreign_key => 'wiki_id'
  belongs_to :parent, :class_name => 'SourceWikiPage', :foreign_key => 'parent_id'

  def self.find_target(source_wiki_page)
    return nil unless source_wiki_page
    wiki = SourceWiki.find_target(source_wiki_page.wiki)
    WikiPage.find_by_title_and_wiki_id(source_wiki_page.title, wiki.id)
  end

  def self.migrate
    all(:order => 'parent_id ASC').each do |source_wiki_page|
      target_wiki_page = SourceWikiPage.find_target(source_wiki_page)

      if target_wiki_page
        puts "  Skipping existing wiki page #{source_wiki_page.title}"
      else
        puts <<LOG
  Migrating wiki page #{source_wiki_page.title}
LOG
        target_wiki_page = WikiPage.create!(source_wiki_page.attributes) do |wp|
          wp.wiki = SourceWiki.find_target(source_wiki_page.wiki)
          wp.parent = SourceWikiPage.find_target(source_wiki_page.parent)
        end
        puts "    mapping: #{source_wiki_page.id} => #{wiki_page.id}"
      end

      RedmineMerge::Mapper.add_wiki_page(source_wiki_page.id, target_wiki_page.id)
    end
  end
end
