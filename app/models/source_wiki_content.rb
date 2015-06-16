class SourceWikiContent < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'wiki_contents'

  belongs_to :author, class_name: 'SourceUser', foreign_key: 'author_id'
  belongs_to :page, class_name: 'SourceWikiPage', foreign_key: 'page_id'

  def self.find_target(source)
    return nil unless source
    WikiContent.find_by_id(RedmineMerge::Mapper.target_id(source)) ||
      WikiContent.where(
        page_id: SourceWikiPage.find_target(source.page)
      ).first
  end

  def self.migrate
    all.each do |source|
      target = SourceWikiContent.find_target(source)
      if target
        puts "  Skipping existing wiki content for page #{source.page.title} by #{source.author}"
      else
        puts <<LOG
  Migrating wiki content for page #{source.page.title}
    author: #{source.author} (#{source.author.id})
    version: #{source.version}
LOG
        target = WikiContent.create!(source.attributes) do |wc|
          wc.page = SourceWikiPage.find_target(source.page)
          wc.author = SourceUser.find_target(source.author)
        end
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
