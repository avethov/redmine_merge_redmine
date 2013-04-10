# Add by Ken Sperow

class SourceMember < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "members"

  belongs_to :principal, :class_name => 'SourcePrincipal', :foreign_key => 'user_id'
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'
  has_many :member_roles, :class_name => 'SourceMemberRole', :foreign_key => 'member_id'
  has_many :roles, :through => :member_roles
  #  has_and_belongs_to_many :source_roles, :class_name => 'SourceRole', :join_table => 'member_roles', :foreign_key => 'member_id', :association_foreign_key => 'role_id'


  
  # Because of the inherited_by field the members that are groups need to migrated first
  def self.migrateGroups    
    all.each do |source_member|      
#      puts "source_member id: #{source_member.id} project: #{source_member.project.name}, user_id: #{source_member.user_id} user: #{source_member.principal.lastname} "

      # Only handle "Groups" in this method
      next if source_member.principal.type != "Group"
      
#      puts "Migrating source_member id: #{source_member.id} project: #{source_member.project.name}, user_id: #{source_member.user_id} user: #{source_member.principal.lastname} "
#
#      migrated_user = Group.find_by_lastname(source_member.principal.lastname) 
#      migrated_project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_member.project_id))
#      puts "migrated_user: #{migrated_user.id} #{migrated_user.lastname}"
#      puts "migrated_project: #{migrated_project.id} #{migrated_project.name}"
#       
#      puts "Migrating member entry"
      
#      source_member.roles.each do |role|
#        puts "Role: #{role.name} id: #{role.id}"      
#      end
                   
      Member.create!(source_member.attributes) do |m|
        m.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_member.project_id))
        m.principal = Group.find_by_lastname(source_member.principal.lastname)
        
#        puts "Initiated roles: #{m.roles}"
#        m.roles.each do |mrole|
#          puts "Initiated Role: #{mrole.name} id: #{mrole.id}"      
#        end
        
        if source_member.roles
          source_member.roles.each do |source_role|
            merged_role = Role.find_by_name(source_role.name)
#            puts "merged_role name:  #{merged_role.name} id: #{merged_role.id}"
            m.roles << merged_role if merged_role
#            puts "After inserting merged_tracker name =  #{merged_tracker.name} id = #{merged_tracker.id}" if merged_tracker
          end
        end
        
        puts "migrated member project: #{m.project.name} Group: #{m.principal.lastname}"
        
      end
    end
    # TODO - add the merged member to a map -- member_roles will need it
  end

# Because of the inherited_by field the members that are groups need to migrated first
def self.migrateMembers    
  all.each do |source_member|
    
#      puts "source_member id: #{source_member.id} project: #{source_member.project.name}, user_id: #{source_member.user_id} user: #{source_member.principal.lastname} "

    next if source_member.principal.type != "User"
    
    # Get only the non-inheritied records
    
#    puts "Migrating source_member id: #{source_member.id} project: #{source_member.project.name}, user_id: #{source_member.user_id} user: #{source_member.principal.lastname} "
#
#    migrated_user = User.find_by_login(source_member.principal.login) 
#    migrated_project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_member.project_id))
#    puts "migrated_user: #{migrated_user.id} "
#    puts "migrated_project: #{migrated_project.id} "
#         
#    puts "Migrating member entry"
#    
#    # only enter member if they don't have any inherited records
#    source_member.member_roles.each do |mr|
#      puts "Role: #{mr.role.name} id: #{mr.role.id} inherited: #{mr.inherited?}"
#    end
    role_ids = source_member.member_roles.reject(&:inherited?).collect(&:role_id)
#    puts " Role_ids: #{role_ids}  source_member.role_ids: #{source_member.role_ids}"
    
    # No need to enter the member if there are no non inherited roles
    next if role_ids.empty?
    
    # Get the new migrated IDs for the roles
    migrated_role_ids = []
    role_ids.each do |rid|
      migrated_role_id = Role.find_by_name(SourceRole.find(rid).name)
#      puts "Role_id: #{rid} new_id: #{migrated_role_id.id} name: #{SourceRole.find(rid).name}"
      migrated_role_ids << migrated_role_id.id
    end
     
    # TODO - only create the member if it does not already exist?  
    Member.create!(source_member.attributes) do |m|
      m.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_member.project_id))
      m.principal = User.find_by_login(source_member.principal.login)
      m.role_ids = migrated_role_ids
#      puts "Initiated roles: #{m.roles}"
#      m.roles.each do |mrole|
#        puts "Initiated Role: #{mrole.name} id: #{mrole.id}"      
#      end
#      
#      if source_member.roles
#        source_member.roles.each do |source_role|
#          merged_role = Role.find_by_name(source_role.name)
#          puts "merged_role name:  #{merged_role.name} id: #{merged_role.id}"
#          m.roles << merged_role if merged_role
##            puts "After inserting merged_tracker name =  #{merged_tracker.name} id = #{merged_tracker.id}" if merged_tracker
#        end
#      end
      
#      puts "migrated member project: #{m.project.name} user: #{m.principal.login}"
      
    end
  end
end
end
