# Added by Ken Sperow
# Groups are stored in the "users" table with a type of "group" and the group name stored in the lastname field - a hack in my opinion
# Users are migrated in the SourceUser class
#
# KS - tried to use inheritance but it did not work as a result of ActiveRecord
#      using the "type" column and the name of the class to put together a query such as:
#
#   SELECT "users".* FROM "users" WHERE "users"."type" IN ('SourceUser')
# -- Note the "SourceUser" type in the query -- the only way I know not to have ActiveRecord not use the type
#    column would be to tell it to overwrite Base.inheritance_column but this could cause issues for Redmine.
#
#class SourceGroup < SourcePrincipal

class SourceGroup < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "users"

  has_and_belongs_to_many :users, :class_name => 'SourceUser', :join_table => 'groups_users', :foreign_key => 'group_id', :association_foreign_key => 'user_id'

  def self.find_target(source)
    return nil unless source
    unless source.is_a?(SourceGroup) || source.is_a?(SourcePrincipal)
      fail "Expected SourceGroup or SourcePrincipal got #{source.class}"
    end
    Group.find_by_lastname(source.lastname)
  end

  def self.migrate_group_users(target_group, source_users)
    source_users.each do |source_user|
      target_user = SourceUser.find_target(source_user)
      if target_group.users.include?(target_user)
        puts "    User #{source_user} already in group"
      else
        puts "    Adding group source_user #{source_user} (#{source_user.id} => #{target_user.id})"
        target_group.users << target_user
      end
    end
    target_group.save
  end

  # ActiveRecord allows class to pull entries out of the database
  def self.migrate
    where(type: 'Group').each do |source_group|
      target_group = SourceGroup.find_target(source_group)
      if target_group
        puts "  Skipping existing group #{source_group.lastname}"
      else
        puts "  Migrating group #{source_group.lastname}"
        target_attributes = source_group.attributes.dup.except('users')
        target_group = Group.create!(target_attributes) do |g|
          g.users = []
        end
      end
      migrate_group_users(target_group, source_group.users)
    end
  end
end
