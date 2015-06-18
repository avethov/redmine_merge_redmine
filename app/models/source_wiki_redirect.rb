# Added by Ken Sperow

class SourceWikiRedirect < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'wiki_redirects'

  belongs_to :wiki, class_name: 'SourceWiki', foreign_key: 'wiki_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceWikiRedirect got #{source.class}" unless source.is_a?(SourceWikiRedirect)
    WikiRedirect.where(
      title: source.title,
      wiki_id: SourceWiki.find_target(source.wiki),
      created_on: source.created_on
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)
      if target
        puts "  Skipping existing wiki redirect #{target.title}"
        next
      end

      puts "  Migrating wiki redirect #{target.title}"
      WikiRedirect.create!(source.attributes) do |wr|
        wr.wiki = SourceWiki.find_target(source.wiki)
      end
    end
  end
end
