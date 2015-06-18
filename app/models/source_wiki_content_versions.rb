class SourceWikiContentVersions < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'wiki_content_versions'

  belongs_to :author, class_name: 'SourceUser', foreign_key: 'author_id'
  belongs_to :page, class_name: 'SourceWikiPage', foreign_key: 'page_id'
  belongs_to :wiki_content, class_name: 'SourceWikiContent', foreign_key: 'wiki_content_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceWikiContentVersions got #{source.class}" unless source.is_a?(SourceWikiContentVersions)
    WikiContentVersions.where(
      version: source.version,
      page_id: SourceWikiPage.find_target(source.page)
    ).first
  end

  def self.create_target(source)
    puts "  Migrating wiki content version for page #{source.page.title} version #{source.version} by #{source.author}"
    WikiContentVersions.create!(source.attributes) do |target|
      target.page = SourceWikiPage.find_target(source.page)
      target.author = SourceUser.find_target(source.author)
      target.wiki_content = SourceWikiContent.find_target(source.wiki_content)

      # Needs to be set explicitly, otherwise postgres laments
      # about a null value for the not-null field `version`.
      target.version = source.version

      target.updated_on = source.updated_on
    end
  end

  def self.migrate
    all.each do |source|
      if SourceWikiContentVersions.find_target(source)
        puts "  Skipping existing content version for #{source.page.title} (##{source.version})"
      else
        create_target(source)
      end
    end
  end
end
