class SourceWikiContentVersions < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "wiki_content_versions"

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'
  belongs_to :page, :class_name => 'SourceWikiPage', :foreign_key => 'page_id'
  belongs_to :wiki_content, :class_name => 'SourceWikiContent', :foreign_key => 'wiki_content_id'

  def self.find_target(source)
    return nil unless source
    page = SourceWikiPage.find_target(source.page)
    WikiContentVersions.find_by_version_and_page_id(source.version, page)
  end

  def self.migrate
    all.each do |swcv|
      target_wiki_content_version = SourceWikiContentVersions.find_target(swcv)

      if target_wiki_content_version
        puts "  Skipping existing content version for #{swcv.page.title} (##{swcv.version})"
        next
      end

      puts <<LOG
  Merging wiki content version for page #{swcv.page.title}
    author: #{swcv.author}
    version: #{swcv.version}
LOG
      WikiContentVersions.create!(swcv.attributes) do |wcv|
        wcv.page = SourceWikiPage.find_target(swcv.page)
        wcv.author_id = SourceUser.find_target(swcv.author).id
        wcv.wiki_content = SourceWikiContent.find_target(swcv.wiki_content)
      end
    end
  end
end
