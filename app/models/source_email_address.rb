class SourceEmailAddress < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'email_addresses'

  belongs_to :user, class_name: 'SourceUser', foreign_key: 'user_id'

  def self.find_or_init_target(source)
    find_target(source) ||
      EmailAddress.new(source.attributes.dup.except('user_id'))
  end

  def self.find_target(source)
    return nil unless source
    fail 'Expected SourceEmailAddress' unless source.is_a?(SourceEmailAddress)
    EmailAddress.find_by_address(source.address)
  end
end
