class SourceAttachment < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'attachments'

  belongs_to :author, class_name: 'SourceUser', foreign_key: 'author_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceAttachment got #{source.class}" unless source.is_a?(SourceAttachment)
    Attachment.where(
      author_id: SourceUser.find_target(source.author),
      container_id: source.container.class.find_target(source.container),
      container_type: source.container_type,
      filename: source.filename,
      created_on: source.created_on
    ).first
  end

  # Needs to be a custom relation accessor because the `polymorphic`
  # option cannot use source models for `SourceAttachment`.
  def container
    source_klass = "Source#{container_type}".constantize
    source_klass.find_by_id(container_id)
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)
      if target
        puts "  Skipping existing attachment for #{source.container}"
        next
      end

      puts "  Migrating attachment for #{source.container}"
      Attachment.create!(source.attributes) do |a|
        a.author    = SourceUser.find_target(source.author)
        a.container = source.container.class.find_target(source.container)
      end
    end
  end
end
