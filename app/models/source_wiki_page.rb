class SourceWikiPage < ActiveRecord::Base
  include SecondDatabase
  set_table_name :wiki_pages

  def self.migrate
    # First migrate the root entries
  all(:conditions => {:parent_id => nil}).each do |source_root_wiki_page|
      puts "source_root_wiki_page.wiki_id: #{source_root_wiki_page.wiki_id}"
      puts "source_root_wiki_page.parent_id: #{source_root_wiki_page.parent_id}"
      
      wiki_page = WikiPage.create!(source_root_wiki_page.attributes) do |wp|
        wp.wiki = Wiki.find(RedmineMerge::Mapper.get_new_wiki_id(source_root_wiki_page.wiki_id))
      end

      puts "Adding page to map, source_root_wiki_page.id: #{source_root_wiki_page.id} migrated_wiki_page.id: #{wiki_page.id}"

      RedmineMerge::Mapper.add_wiki_page(source_root_wiki_page.id, wiki_page.id)
    end
    
    # Now migrate the child pages
    all(:order => 'parent_id ASC', :conditions => ["parent_id IS NOT NULL"]).each do |source_wiki_page|
      puts "source_wiki_page.wiki_id: #{source_wiki_page.wiki_id}"
      puts "source_wiki_page.parent_id: #{source_wiki_page.parent_id}"
      
      wiki_page = WikiPage.create!(source_wiki_page.attributes) do |wp|
        wp.wiki = Wiki.find(RedmineMerge::Mapper.get_new_wiki_id(source_wiki_page.wiki_id))
        wp.parent = WikiPage.find(RedmineMerge::Mapper.get_new_wiki_page_id(source_wiki_page.parent_id)) if source_wiki_page.parent_id
      end

      puts "Adding page to map, source_wiki_page.id: #{source_wiki_page.id} migrated_wiki_page.id: #{wiki_page.id}"

      RedmineMerge::Mapper.add_wiki_page(source_wiki_page.id, wiki_page.id)
    end
  end
end
