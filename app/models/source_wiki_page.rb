class SourceWikiPage < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'wiki_pages'

  belongs_to :wiki, class_name: 'SourceWiki', foreign_key: 'wiki_id'
  belongs_to :parent, class_name: 'SourceWikiPage', foreign_key: 'parent_id'

  def to_s
    "SourceWikiPage #{title}"
  end

  def self.find_target(source)
    return nil unless source
    WikiPage.where(
      title: source.title,
      wiki_id: SourceWiki.find_target(source.wiki)
    ).first
  end

  def self.migrate
    order(parent_id: :asc).each do |source|
      target = SourceWikiPage.find_target(source)

      if target
        puts "  Skipping existing wiki page #{source.title}"
      else
        puts "Migrating wiki page #{source.title}"
        target = WikiPage.create!(source.attributes) do |wp|
          wp.wiki = SourceWiki.find_target(source.wiki)
          wp.parent = SourceWikiPage.find_target(source.parent)
        end
        puts "    mapping: #{source.id} => #{target.id}"
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
