# KS - tried to use inheritance but it did not work as a result of ActiveRecord
#      using the "type" column and the name of the class to put together a query such as:
#
#   SELECT "users".* FROM "users" WHERE "users"."type" IN ('SourceUser')
# -- Note the "SourceUser" type in the query -- the only way I know not to have ActiveRecord not use the type
#    column would be to tell it to overwrite Base.inheritance_column but this could cause issues for Redmine.
#
#class SourceUser < SourcePrincipal

class SourceUser < ActiveRecord::Base
  include SecondDatabase

  self.table_name = "users"

  has_and_belongs_to_many :groups, :class_name => 'SourceGroup', :join_table => 'groups_users', :foreign_key => 'user_id', :association_foreign_key => 'group_id'
  has_many :email_addresses, class_name: 'SourceEmailAddress'

  def self.find_target(user, options = { fail: true })
    target = User.where(login: user.login).first ||
             User.having_mail(user.mails).first
    if target.nil? && options[:fail]
      fail "No target found with mails #{user.mails.inspect} or login `#{user.login}`"
    end
    target
  end

  # ActiveRecord allows class to pull entries out of the database
  def self.migrate
    where(type: 'User').each do |source|
      if SourceUser.find_target(source, fail: false)
        puts "  Skipping existing user #{source}"
        next
      end

      puts "  Migrating user #{source}"
      User.create!(source.attributes) do |target|
        target.login = source.login
        target.admin = source.admin
        target.hashed_password = source.hashed_password

        target.email_addresses = source.email_addresses.map do |source_mail|
          SourceEmailAddress.find_target(source_mail) ||
            begin
              mail = EmailAddress.new(source_mail.attributes.dup.except('user_id'))
              mail.created_on = DateTime.now
              mail.updated_on = DateTime.now
              mail
            end
        end

        if target.email_addresses.empty?
          target.email_address =
            begin
              mail = EmailAddress.new(address: "#{source.login}@redmine-merge.com", notify: false, is_default: true)
              mail.created_on = DateTime.now
              mail.updated_on = DateTime.now
              mail
            end
        end
      end
    end
  end
end
