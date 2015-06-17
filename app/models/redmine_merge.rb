class RedmineMerge
  def self.migrate
    # Keep the source records timestamps
    ActiveRecord::Base.record_timestamps = false

    puts 'About to migrate users'
    SourceUser.migrate
    puts 'Done migrating users'

    puts 'About to migrate UserPreferences'
    SourceUserPreference.migrate
    puts 'Done migrating UserPreferences'

    puts 'About to migrate groups'
    SourceGroup.migrate
    puts 'Done migrating groups'

    puts 'About to migrate CustomFields'
    SourceCustomField.migrate
    puts 'Done migrating CustomFields'
    puts 'About to migrate Trackers'
    SourceTracker.migrate
    puts 'Done migrating Tracker'
    puts 'About to migrate IssueStatus'
    SourceIssueStatus.migrate
    puts 'Done migrating IssueStatus'
    puts 'About to migrate Roles'
    SourceRole.migrate
    puts 'Done migrating Roles'
    puts 'About to migrate Workflows'
    SourceWorkflow.migrate
    puts 'Done migrating Workflows'

    # Project-specific data
    puts 'About to migrate Project'
    SourceProject.migrate
    puts 'Done migrating Project'

    puts 'About to migrate Queries'
    SourceQuery.migrate
    puts 'Done migrating Queries'

    puts 'About to migrate Repositories'
    SourceRepository.migrate
    puts 'Done migrating Repositories'

    puts 'About to migrate Member Members'
    SourceMember.migrate_members
    puts 'Done migrating Member Members'
    puts 'About to migrate Member Groups'
    SourceMember.migrate_groups
    puts 'Done migrating Member Groups'

    puts 'About to migrate Version'
    SourceVersion.migrate
    puts 'Done migrating Version'
    puts 'About to migrate News'
    SourceNews.migrate
    puts 'Done migrating News'
    puts 'About to migrate IssueCategory'
    SourceIssueCategory.migrate
    puts 'Done migrating IssueCategory'
    puts 'About to migrate issue_priorities'
    SourceEnumeration.migrate_issue_priorities
    puts 'Done migrating issue_priorities'
    puts 'About to migrate time_entry_activities'
    SourceEnumeration.migrate_time_entry_activities
    puts 'Done migrating time_entry_activities'
    puts 'About to migrate document_categories'
    SourceEnumeration.migrate_document_categories
    puts 'Done migrating document_categories'

    puts 'About to migrate Document'
    SourceDocument.migrate
    puts 'Done migrating Document'
    puts 'About to migrate Wiki'
    SourceWiki.migrate
    puts 'Done migrating Wiki'
    puts 'About to migrate WikiPage'
    SourceWikiPage.migrate
    puts 'Done migrating WikiPage'
    puts 'About to migrate WikiContent'
    SourceWikiContent.migrate
    puts 'Done migrating WikiContent'
    puts 'About to migrate WikiContentVersions'
    SourceWikiContentVersions.migrate
    puts 'Done migrating WikiContentVersions'
    puts 'About to migrate WikiRedirect'
    SourceWikiRedirect.migrate
    puts 'Done migrating WikiRedirect'

    puts 'About to migrate Issue'
    SourceIssue.migrate
    puts 'Done migrating Issue'
    puts 'About to migrate IssueRelation'
    SourceIssueRelation.migrate
    puts 'Done migrating IssueRelation'

    puts 'About to migrate Watchers'
    SourceWatcher.migrate
    puts 'Done migrating Watchers'
    puts 'About to migrate CustomValues'
    SourceCustomValue.migrate
    puts 'Done migrating CustomValues'

    puts 'About to migrate Journal'
    SourceJournal.migrate
    puts 'Done migrating Journal'
    puts 'About to migrate JournalDetail'
    SourceJournalDetail.migrate
    puts 'Done migrating JournalDetail'

    puts 'About to migrate TimeEntry'
    SourceTimeEntry.migrate
    puts 'Done migrating TimeEntry'

    puts 'About to migrate Attachment'
    SourceAttachment.migrate
    puts 'Done migrating Attachment'
  end

  class Mapper
    def self.mappings
      @mappings ||= {}
    end

    def self.mapping(table_name)
      mappings[table_name] ||= {}
    end

    def self.map(source, target)
      mapping(source.class.table_name)[source.id.to_i] = target.id
    end

    def self.target_id(*args)
      table_name, source_id =
        if args.first.is_a?(String)
          [args.first, args.second]
        else
          source = args.first
          return nil unless source
          [source.class.table_name, source.id]
        end
      mapping(table_name)[source_id.to_i]
    end

    # Add logic to replace any issue number found within the description (e.g.,#1234) with the new issue number
    # - Pull out the matching issue number string from the "description"
    # - Determine if the issue number matches a source issue number, if so get the merged issue number
    # - Replace the source issue number with the merged issue number in the "notes" column
    def self.replace_issue_refs(str)
      str = str.dup
      refs = str.scan(/#([\d]+)/).flatten
      refs.each do |ref|
        source_issue_id = ref.gsub(/#/, '').to_i
        target_issue_id = mapping('issues')[source_issue_id]
        puts "=> Updating ref #{ref} with ##{target_issue_id}"
        str.gsub!("#{ref}", "##{target_issue_id}") if target_issue_id
      end
      str
    end
  end
end
