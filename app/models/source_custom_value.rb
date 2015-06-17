class SourceCustomValue < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'custom_values'

  CUSTOMIZABLE_TYPES = %w(Issue Document WikiPage Project Version News)

  belongs_to :custom_field, class_name: 'SourceCustomField', foreign_key: 'custom_field_id'

  def self.find_target(source)
    return nil unless source
    CustomValue.where(
      customized_type: source.customized_type,
      customized_id: source.customized.class.find_target(source.customized),
      custom_field_id: SourceCustomField.find_target(source.custom_field),
    ).first
  end

  # Needs to be a custom relation accessor because the `polymorphic`
  # option cannot use source models for `SourceCustomValue`.
  def customized
    @customized_memo ||=
      begin
        source_klass = "Source#{customized_type}".constantize
        source_klass.find_by_id(customized_id)
      end
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)
      if target
        puts "  Skipping existing custom value #{target.custom_field.name}"
        next
      end

      puts "  Migrating custom value for field #{source.custom_field.name}"
      CustomValue.create!(source.attributes) do |cv|
        cv.custom_field = SourceCustomField.find_target(source.custom_field)
        cv.customized   = source.customized.class.find_target(source.customized)
      end
    end
  end
end
