class SourceEmailAddress < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'email_addresses'

  belongs_to :user, class_name: 'SourceUser', foreign_key: 'user_id'
end
