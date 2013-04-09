# Created by Ken Sperow

class SourceRole < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "roles"
  
  has_many :member_roles, :class_name => 'SourceMemberRoles'
  has_many :members, :through => :member_roles

  def self.migrate
    all.each do |source_role|
      # Only migrate the role if it doesn't already exist
      next if Role.find_by_name(source_role.name)

      Role.create!(source_role.attributes)
    end
  end
end
