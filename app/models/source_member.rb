# Add by Ken Sperow

class SourceMember < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'members'

  belongs_to :principal, class_name: 'SourcePrincipal'
  belongs_to :project,   class_name: 'SourceProject'

  has_many :member_roles, class_name: 'SourceMemberRole', foreign_key: 'member_id'
  has_many :roles, through: :member_roles

  scope :groups, -> { joins(:principal).where(users: { type: 'Group' }) }
  scope :users, -> { joins(:principal).where(users: { type: 'User' }) }

  def self.find_target(source_member)
    Member.where(
      user_id: SourceUser.find_target(source_member.principal),
      project_id: SourceProject.find_target(source_member.project)
    ).first
  end

  def self.find_group_target(source_member)
    Member.where(
      user_id: SourceGroup.find_target(source_member.principal),
      project_id: SourceProject.find_target(source_member.project)
    ).first
  end

  # Because of the inherited_by field the members that are groups need to migrated first
  def self.migrate_groups
    groups.each do |source_member|
      target_member = SourceMember.find_group_target(source_member)
      if target_member
        puts "  Skipping existing group membership #{source_member.principal} for project #{source_member.project.identifier}"
      else
        puts <<LOG
  Migrating group membership
    project: #{source_member.project.name}
    group: #{source_member.principal}
LOG
        Member.create!(source_member.attributes) do |m|
          m.project   = SourceProject.find_target(source_member.project)
          m.principal = SourceGroup.find_target(source_member.principal)

          Array(source_member.member_roles).each do |source_member_role|
            target_role = SourceRole.find_target(source_member_role.role)
            if target_role && !m.roles.include?(target_role)
              m.roles << target_role
            end
          end
        end
      end
    end
  end

  # Because of the inherited_by field the members that are groups need to migrated first
  def self.migrate_members
    users.each do |source_member|
      target_member = SourceMember.find_target(source_member)
      if target_member
        puts "  Skipping existing user membership #{source_member.principal} for project #{source_member.project.identifier}"
        next
      end

      member_roles = source_member.member_roles.reject(&:inherited?)

      # No need to enter the member if there are no non inherited roles
      next if member_roles.empty?

      puts <<LOG
  Migrating user membership
    project: #{source_member.project.name}
    principal: #{source_member.principal}
LOG
      Member.create!(source_member.attributes) do |m|
        m.project   = SourceProject.find_target(source_member.project)
        m.principal = SourceUser.find_target(source_member.principal)

        member_roles.each do |source_member_role|
          target_role = SourceRole.find_target(source_member_role.role)
          if target_role && !m.roles.include?(target_role)
            m.roles << target_role
          end
        end
      end
    end
  end
end
