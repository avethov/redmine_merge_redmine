class SourceMemberRole < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "member_roles"
  belongs_to :member, :class_name => 'SourceMember', :foreign_key => 'member_id'
  belongs_to :role, :class_name => 'SourceRole', :foreign_key => 'role_id'
  

  def inherited?
    !inherited_from.nil?
  end
end