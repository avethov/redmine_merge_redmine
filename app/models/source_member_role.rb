class SourceMemberRole < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "member_roles"
  belongs_to :member, :class_name => 'SourceMember', :foreign_key => 'member_id'
  belongs_to :role, :class_name => 'SourceRole', :foreign_key => 'role_id'

  def self.find_target(source_member_role)
    return nil unless source_member_role
    fail "Expected SourceMemberRole got #{source_member_role.class}" unless source_member_role.is_a?(SourceMemberRole)
    MemberRole.where(
      member_id: SourceMember.find_target(source_member_role.member),
      role_id: SourceRole.find_target(source_member_role.role)
    ).first
  end

  def inherited?
    !inherited_from.nil?
  end
end
