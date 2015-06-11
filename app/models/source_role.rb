class SourceRole < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'roles'

  has_many :member_roles, :class_name => 'SourceMemberRoles'
  has_many :members, :through => :member_roles

  def self.find_target(source_role)
    return nil unless source_role
    Role.find_by_name(source_role.name)
  end

  def self.migrate
    all.each do |source_role|
      if SourceRole.find_target(source_role)
        puts "  Skipping existing role #{source_role.name}"
        next
      end

      puts "  Migrating role #{source_role.name}"
      Role.create!(source_role.attributes)
    end
  end
end
