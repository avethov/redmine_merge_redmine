class SourceJournalDetail < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'journal_details'

  belongs_to :journal, class_name: 'SourceJournal', foreign_key: 'journal_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceJournalDetail got #{source.class}" unless source.is_a?(SourceJournalDetail)
    JournalDetail.where(
      journal_id: SourceJournal.find_target(source.journal),
      property:   source.property,
      prop_key:   source.prop_key,
      old_value:  source.target_old_value,
      value:      source.target_value
    ).first
  end

  def val_class
    property_name = prop_key.to_s.gsub(/\_id$/, '').to_sym
    journalized_class = journal.journalized_type.constantize
    association = journalized_class.reflect_on_all_associations.detect do |a|
      a.name == property_name
    end
    fail "Missing association #{property_name}" unless association
    association.klass
  end

  def target_old_value
    # Need to remap propery keys to their new ids
    if prop_key.include?('_id')
      RedmineMerge::Mapper.target_id(val_class.find_by_id(old_value))
    else
      old_value
    end
  end

  def target_value
    # Need to remap propery keys to their new ids
    if prop_key.include?('_id')
      RedmineMerge::Mapper.target_id(val_class.find_by_id(value))
    else
      value
    end
  end

  def self.migrate
    order(journal_id: :asc).each do |source|
      target_journal = SourceJournal.find_target(source.journal)
      unless target_journal
        puts '  Skipping details for missing journal'
        next
      end

      target = find_target(source)
      if target
        puts "  Skipping existing journal ##{target_journal.id} details - #{source.property} #{source.prop_key}"
        next
      end

      puts "  Migrating journal ##{target_journal.id} details - #{source.property} #{source.prop_key}"
      JournalDetail.create!(source.attributes) do |jd|
        jd.journal   = target_journal
        jd.old_value = source.target_old_value
        jd.value     = source.target_value
      end
    end
  end
end
