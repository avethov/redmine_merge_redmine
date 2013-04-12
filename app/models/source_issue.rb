class SourceIssue < ActiveRecord::Base

  include SecondDatabase

  self.table_name = "issues"
  
  def self.migrate

    puts "There are #{all.count} issues to migrate"

    all.each do |source_issue|

      puts "Source issue.id = #{source_issue.id}"

      assignedTo = SourcePrincipal.find_by_id(source_issue.assigned_to_id)      
      puts "  Source 'assigned to' ID = #{source_issue.assigned_to_id}"
      if (assignedTo && assignedTo.type == "User")
        puts "  'Assigned to' login = #{assignedTo.login}"
        mergedAssignedTo = User.find_by_login(assignedTo.login)
        puts "   Merged 'Assigned to' login = #{mergedAssignedTo.login}"
      end
      if (assignedTo && assignedTo.type == "Group")
        puts "  'Assigned to' group name = #{assignedTo.lastname}" 
        mergedAssignedTo = Group.find_by_lastname(assignedTo.lastname)
        puts "   Merged 'Assigned to' lastname = #{mergedAssignedTo.lastname}"
      end

      author = SourceUser.find_by_id(source_issue.author_id)
      puts "  Source author ID = #{source_issue.author_id}"
      puts "  Author login = #{author.login}"

      category = SourceIssueCategory.find_by_id(source_issue.category_id)
      puts "  Source category ID = #{source_issue.category_id}"
      puts "  Category name = #{category.name}" if category

      puts "  Source fixed version ID = #{source_issue.fixed_version_id}"

      priority = SourceEnumeration.find_by_id(source_issue.priority_id)
      puts "  Source priority ID = #{source_issue.priority_id}"
      puts "  Priority name = #{priority.name}"

      project = SourceProject.find_by_id(source_issue.project_id)
      puts "  Source project ID = #{source_issue.project_id}"
      puts "  Project ID = #{project.id}"

      status = SourceIssueStatus.find_by_id(source_issue.status_id)
      puts "  Source status ID = #{source_issue.status_id}"
      puts "  Status name = #{status.name}"

      tracker = SourceTracker.find_by_id(source_issue.tracker_id)
      puts "  Source tracker ID = #{source_issue.tracker_id}"
      puts "  Tracker name = #{tracker.name}"
      
      mergedAuthor = User.find_by_login(author.login)
      source_issue.author_id = mergedAuthor.id 
      puts "  New author id: #{source_issue.author_id} "
      source_issue.project_id = RedmineMerge::Mapper.get_new_project_id(project.id)
      source_issue.assigned_to_id = mergedAssignedTo.id if assignedTo
      if source_issue.fixed_version_id
        source_issue.fixed_version_id = RedmineMerge::Mapper.get_new_version_id(source_issue.fixed_version_id)
      end

      attributes = source_issue.attributes.dup.except('parent_id', 'lft', 'rgt')

      issue = Issue.create!(attributes) do |i|
        i.category = IssueCategory.find_by_name(category.name) if category
        i.priority = IssuePriority.find_by_name(priority.name)
        i.status = IssueStatus.find_by_name(status.name)
        i.tracker = Tracker.find_by_name(tracker.name)
      end

      puts "  Created issue #{issue.id}:"
      puts "    Subject = #{issue.subject}"
      puts "    Tracker ID = #{issue.tracker.id}"
      puts "    Tracker name = #{issue.tracker.name}"

      RedmineMerge::Mapper.add_issue(source_issue.id, issue.id)

    end

  end

end
