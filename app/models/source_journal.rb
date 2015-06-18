class SourceJournal < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'journals'

  belongs_to :user, class_name: 'SourceUser', foreign_key: 'user_id'

  # Needs to be a custom relation accessor because the `polymorphic`
  # option cannot use source models for `SourceJournal`.
  def journalized
    source_klass = "Source#{journalized_type}".constantize
    source_klass.find_by_id(journalized_id)
  end

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceJournal got #{source.class}" unless source.is_a?(SourceJournal)
    Journal.find_by_id(RedmineMerge::Mapper.target_id(source)) ||
      Journal.where(
        journalized_id:   source.journalized.class.find_target(source.journalized),
        journalized_type: source.journalized_type,
        user_id:          SourceUser.find_target(source.user),
        created_on:       source.created_on
      ).first
  end

  def self.migrate
    order(journalized_id: :asc).each do |source|
      unless source.journalized
        puts "  Skipping journal for missing journalized #{source.journalized_type} ##{source.journalized_id}"
        next
      end

      target = find_target(source)
      if target
        puts "  Skipping existing journal for #{target.journalized_type} ##{target.journalized_id}"
      else
        puts "  Migrating journal for #{source.journalized_type} ##{source.journalized_id}"
        target = Journal.create!(source.attributes) do |j|
          j.user        = SourceUser.find_target(source.user)
          j.journalized =
            source.journalized.class.find_target(source.journalized)

          if source.notes
            j.notes = RedmineMerge::Mapper.replace_issue_refs(source.notes)
          end
        end
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
