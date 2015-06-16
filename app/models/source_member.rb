# Add by Ken Sperow

class SourceMember < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'members'

  belongs_to :principal, :class_name => 'SourcePrincipal', :foreign_key => 'user_id'
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'
  has_many :member_roles, :class_name => 'SourceMemberRole', :foreign_key => 'member_id'
  has_many :roles, :through => :member_roles

  def self.groups
    joins(:principal).all(:conditions => { :users => { type: 'Group' }})
  end

  def self.users
    joins(:principal).all(:conditions => { :users => { type: 'User' }})
  end

  def self.find_target(source_member)
    principal = SourceUser.find_target(source_member.principal)
    project   = SourceProject.find_target(source_member.project)
    Member.find_by_user_id_and_project_id(principal.id, project.id)
  end

  def self.find_group_target(source_member)
    principal = Group.find_by_lastname(source_member.principal.lastname)
    project   = SourceProject.find_target(source_member.project)
    Member.find_by_user_id_and_project_id(principal.id, project.id)
  end

  # Because of the inherited_by field the members that are groups need to migrated first
  def self.migrateGroups
    # Only handle "Groups" in this method
    groups.each do |source_member|
      target_member = SourceMember.find_group_target(source_member)
      if target_member
        puts "  Skipping existing group membership #{source_member.principal} for project #{source_member.project.identifier}"
      else
        Member.create!(source_member.attributes) do |m|
          m.project = SourceProject.find_target(source_member.project)
          m.principal = Group.find_by_lastname(source_member.principal.lastname)

          Array(source_member.roles).each do |source_role|
            target_role = SourceRole.find_target(source_role)
            m.roles << target_role if target_role
          end

          puts <<LOG
  Migrated group membership
    project: #{m.project.name}
    group: #{m.principal.lastname}
LOG
        end
      end
    end
  end

  # Because of the inherited_by field the members that are groups need to migrated first
  def self.migrateMembers
    # Only handle "Users" in this method
    users.each do |source_member|
      target_member = SourceMember.find_target(source_member)
      if target_member
        puts "  Skipping existing user membership #{source_member.principal} for project #{source_member.project.identifier}"
        next
      end

      roles = source_member.member_roles.reject(&:inherited?)

      # No need to enter the member if there are no non inherited roles
      next if roles.empty?

      puts <<LOG
  Migrating user membership
    project: #{m.project.name}
    principal: #{m.principal}
LOG
      Member.create!(source_member.attributes) do |m|
        m.project   = SourceProject.find_target(source_member.project)
        m.principal = SourceUser.find_target(source_member.principal)

        roles.each do |role|
          target_role = SourceRole.find_target(role)
          unless target_role.nil? && m.roles.include?(target_role)
            m.roles << target_role.id
          end
        end
      end
    end
  end
end
