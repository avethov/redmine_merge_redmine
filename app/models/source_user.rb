class SourceUser < ActiveRecord::Base
  include SecondDatabase

  self.table_name = 'users'

  # Override inheritance for Source models does not change anythong on
  # the target redmine models.
  self.inheritance_column = :_type_disabled

  has_and_belongs_to_many :groups, class_name: 'SourceGroup', join_table: 'groups_users', foreign_key: 'user_id', association_foreign_key: 'group_id'
  has_many :email_addresses, class_name: 'SourceEmailAddress', foreign_key: 'user_id'
  has_one :email_address, -> { where is_default: true }, class_name: 'SourceEmailAddress', foreign_key: 'user_id', autosave: true

  def mails
    email_addresses.pluck(:address)
  end

  def mail
    email_address.try(:address)
  end

  def to_s
    "#{firstname} #{lastname}"
  end

  def self.find_target(source, options = { fail: true })
    fail "Expected SourceUser got #{source.class}" unless source.is_a?(SourceUser)
    target = User.where(login: source.login).first ||
             User.having_mail(source.mails).first
    if target.nil? && options[:fail]
      fail "No target found with mails #{source.mails.inspect} or login `#{source.login}`"
    end
    target
  end

  def self.migrate
    where(type: 'User').each do |source|
      target = SourceUser.find_target(source, fail: false)
      if target
        puts "  Skipping existing user. #{source} (#{source.mail}) => #{target} (#{target.mail})"
        next
      end

      puts "  Migrating user #{source} (#{source.mail})"
      target = User.create!(source.attributes) do |u|
        u.login = source.login
        u.admin = source.admin
        u.hashed_password = source.hashed_password
        u.email_address = SourceEmailAddress.find_or_init_target(source.email_address)
        unless u.email_address
          u.email_address = EmailAddress.new(
            address: source.mail || "#{source.login}@redmine-merge.com",
            notify: false,
            is_default: true)
        end
      end

      puts "    target user #{target} (#{target.mail})"
    end
  end
end
