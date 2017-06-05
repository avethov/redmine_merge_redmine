# Added by Ken Sperow
# Depends on user and watchable_id, which can point to an issue, wiki_page, or news

class SourceWatcher < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'watchers'

  WATCHABLE_TYPES = %w(Issue Document WikiPage Project Version News EnabledModule)

  belongs_to :user, class_name: 'SourceUser', foreign_key: 'user_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceWatcher got #{source.class}" unless source.is_a?(SourceWatcher)
    Watcher.where(
      user_id: SourceUser.find_target(source.user),
      watchable_id: find_watchable_target(source.watchable_type, source.watchable)
    ).first
  end

  # Needs to be a custom relation accessor because the `polymorphic`
  # option cannot use source models for `SourceWatcher`.
  def watchable
    source_klass = "Source#{watchable_type}".constantize
    source_klass.find_by_id(watchable_id)
  end

  def self.find_watchable_target(type, source)
    fail "Unknown watchable type: #{type}" unless WATCHABLE_TYPES.include?(type)
    source_klass = "Source#{type}".constantize
    source_klass.find_target(source)
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)
      if target
        puts '  Skipping existing watcher'
        next
      end

      # Don't migrate watcher entries for News events where the News author is the watcher
      if source.watchable_type == 'News' && source.watchable.author == source.user
        puts '  Skipping watcher for news author'
        next
      end

      user = SourceUser.find_target(source.user)
      # The `Watcher` model checks for the `active?` state while validating.
      unless user.active?
        puts '  Skipping watcher for inactive user'
        next
      end

      Watcher.create!(source.attributes) do |w|
        w.watchable = find_watchable_target(source.watchable_type, source.watchable)
        w.user      = user
      end
    end
  end
end
