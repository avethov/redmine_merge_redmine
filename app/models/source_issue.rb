class SourceIssue < Issue
  include SecondDatabase
  self.table_name = 'issues'

  belongs_to :root,          class_name: 'SourceIssue'
  belongs_to :parent,        class_name: 'SourceIssue'
  belongs_to :assigned_to,   class_name: 'SourcePrincipal'
  belongs_to :author,        class_name: 'SourceUser'
  belongs_to :category,      class_name: 'SourceIssueCategory'
  belongs_to :priority,      class_name: 'SourceEnumeration'
  belongs_to :project,       class_name: 'SourceProject'
  belongs_to :status,        class_name: 'SourceIssueStatus'
  belongs_to :tracker,       class_name: 'SourceTracker'
  belongs_to :fixed_version, class_name: 'SourceVersion'

  def to_s
    "Issue ##{id} - #{subject}"
  end

  def self.find_target(source)
    return unless source
    fail "Expected SourceIssue got #{source.class}" unless source.is_a?(SourceIssue)
    Issue.find_by_id(RedmineMerge::Mapper.target_id(source)) ||
      Issue.where(
        project_id: SourceProject.find_target(source.project),
        author_id: SourceUser.find_target(source.author),
        subject: source.subject,
        created_on: source.created_on
      ).first
  end

  def self.migrate
    puts "There are #{all.count} issues to migrate"
    order(id: :asc).each do |source|

      target = find_target(source)
      if target
        puts "  Skipping existing issue ##{target.id} - #{target.subject}"
      else
        puts "  Migrating issue ##{source.id} - #{source.subject}"
        attributes = source.attributes.dup.except('parent_id', 'lft', 'rgt')
        target = TargetIssue.create!(attributes) do |i|
          i.id         = (source.id + 10000)
          i.subject    = source.subject
          i.lft        = source.lft
          i.rgt        = source.rgt
          i.updated_on = source.updated_on
          i.created_on = source.created_on

          parent = SourceIssue.find_target(source.parent)
          i.parent_id = parent.id if parent
          root = SourceIssue.find_target(source.root)
          i.root_id = root.id if root

          i.fixed_version = SourceVersion.find_target(source.fixed_version)
          i.project       = SourceProject.find_target(source.project)
          i.author        = SourceUser.find_target(source.author)
          i.assigned_to   = SourcePrincipal.find_target(source.assigned_to)
          i.category      = SourceIssueCategory.find_target(source.category)
          i.priority      = SourceEnumeration.find_target(source.priority)
          i.status        = SourceIssueStatus.find_target(source.status)
          i.tracker       = SourceTracker.find_target(source.tracker)
          i.description   = RedmineMerge::Mapper.replace_issue_refs(source.description) if source.description
        end
        puts "    target: ##{target.id} - #{target.subject}"
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
