class RedmineMerge
  def self.migrate
    puts "About to migrate users"    
    SourceUser.migrate
    puts "Done migrating users"
    
    puts "About to migrate groups"    
    SourceGroup.migrate
    puts "Done migrating groups"

    puts "About to migrate CustomFields"
    SourceCustomField.migrate
    puts "Done migrating CustomFields"
    puts "About to migrate Trackers"
    SourceTracker.migrate
    puts "Done migrating Tracker"
    puts "About to migrate IssueStatus"
    SourceIssueStatus.migrate
    puts "Done migrating IssueStatus"
    puts "About to migrate Roles"
    SourceRole.migrate
    puts "Done migrating Roles"
    puts "About to migrate Workflows"
    SourceWorkflow.migrate
    puts "Done migrating Workflows"
    

    # Project-specific data
    puts "About to migrate Project"
    SourceProject.migrate
    puts "Done migrating Project"

    puts "About to migrate Queries"
    SourceQuery.migrate
    puts "Done migrating Queries"    
    
    puts "About to migrate Repositories"
    SourceRepository.migrate
    puts "Done migrating Repositories"  
    
    puts "About to migrate Member Members"
    SourceMember.migrateMembers
    puts "Done migrating Member Members"
    puts "About to migrate Member Groups"
    SourceMember.migrateGroups
    puts "Done migrating Member Groups" 
    
    puts "About to migrate Version"
    SourceVersion.migrate
    puts "Done migrating Version"
    puts "About to migrate News"
    SourceNews.migrate
    puts "Done migrating News"
    puts "About to migrate IssueCategory"
    SourceIssueCategory.migrate
    puts "Done migrating IssueCategory"
    puts "About to migrate issue_priorities"
    # KS - moved from above since they reference projects 
    SourceEnumeration.migrate_issue_priorities
    puts "Done migrating issue_priorities"
    puts "About to migrate time_entry_activities"
    SourceEnumeration.migrate_time_entry_activities
    puts "Done migrating time_entry_activities"
    puts "About to migrate document_categories"
    SourceEnumeration.migrate_document_categories
    puts "Done migrating document_categories"

    puts "About to migrate Document"
    SourceDocument.migrate
    puts "Done migrating Document"
    puts "About to migrate Wiki"
    SourceWiki.migrate
    puts "Done migrating Wiki"
    puts "About to migrate WikiPage"
    SourceWikiPage.migrate
    puts "Done migrating WikiPage"
    puts "About to migrate WikiContent"
    SourceWikiContent.migrate
    puts "Done migrating WikiContent"
    puts "About to migrate WikiContentVersions"
    SourceWikiContentVersions.migrate
    puts "Done migrating WikiContentVersions"
    puts "About to migrate WikiRedirect"
    SourceWikiRedirect.migrate
    puts "Done migrating WikiRedirect"
    # The remaining tables are associated with the "issues" table
    
    puts "About to migrate Issue"
    SourceIssue.migrate
    puts "Done migrating Issue"
    puts "About to migrate IssueRelation"
    SourceIssueRelation.migrate
    puts "Done migrating IssueRelation"
    puts "About to migrate Journal"
    SourceJournal.migrate
    puts "Done migrating Journal"
    puts "About to migrate JournalDetail"
    SourceJournalDetail.migrate
    puts "Done migrating JournalDetail"
    puts "About to migrate TimeEntry"
    SourceTimeEntry.migrate
    puts "Done migrating TimeEntry"
    puts "About to migrate Attachment"
    SourceAttachment.migrate
    puts "Done migrating Attachment"

  end

  class Mapper
    Projects = {}
    Issues = {}
    Journals = {}
    Wikis = {}
    WikiPages = {}
    WikiContent = {}
    Documents = {}
    Versions = {}
    # Added by KS
    News = {}

    def self.add_project(source_id, new_id)
      Projects[source_id] = new_id
    end

    def self.get_new_project_id(source_id)
      Projects[source_id]
    end

    def self.add_issue(source_id, new_id)
      Issues[source_id] = new_id
    end

    def self.get_new_issue_id(source_id)
      Issues[source_id]
    end

    def self.add_journal(source_id, new_id)
      Journals[source_id] = new_id
    end

    def self.get_new_journal_id(source_id)
      Journals[source_id]
    end

    def self.add_wiki(source_id, new_id)
      Wikis[source_id] = new_id
    end

    def self.get_new_wiki_id(source_id)
      Wikis[source_id]
    end

    def self.add_wiki_content(source_id, new_id)
      WikiContent[source_id] = new_id
    end

    def self.get_new_wiki_content_id(source_id)
      WikiContent[source_id]
    end
    
    def self.add_wiki_page(source_id, new_id)
      WikiPages[source_id] = new_id
    end

    def self.get_new_wiki_page_id(source_id)
      WikiPages[source_id]
    end

    def self.add_document(source_id, new_id)
      Documents[source_id] = new_id
    end

    def self.get_new_document_id(source_id)
      Documents[source_id]
    end

    def self.add_version(source_id, new_id)
      Versions[source_id] = new_id
    end

    def self.get_new_version_id(source_id)
      Versions[source_id]
    end

    # KS - Added to handle News so attachments pointing to News entries work correctly
    def self.add_news(source_id, new_id)
      News[source_id] = new_id
    end

    def self.get_new_news_id(source_id)
      News[source_id]
    end
# End KS
    
    def self.find_id_by_property(target_klass, source_id)
      # Similar to issues_helper.rb#show_detail
      source_id = source_id.to_i
      
      puts "In find_id_by_property target_klass: #{target_klass} source_id: #{source_id}"

      case target_klass.to_s
      when 'Project'
        return Mapper.get_new_journal_id(source_id)
      when 'IssueStatus'
        target = find_target_record_from_source(SourceIssueStatus, IssueStatus, :name, source_id)
        return target.id if target
        return nil
      when 'Tracker'
        target = find_target_record_from_source(SourceTracker, Tracker, :name, source_id)
        return target.id if target
        return nil
      when 'User'
        target = find_target_record_from_source(SourceUser, User, :login, source_id)
        return target.id if target
        return nil
      when 'News'
        return Mapper.get_new_news_id(source_id)
      when 'Enumeration'
        target = find_target_record_from_source(SourceEnumeration, Enumeration, :name, source_id)
        return target.id if target
        return nil
      when 'IssueCategory'
        source = SourceIssueCategory.find_by_id(source_id)
        return nil unless source
        target = IssueCategory.find_by_name_and_project_id(source.name, RedmineMerge::Mapper.get_new_project_id(source.project_id))
        return target.id if target
        return nil
      when 'Version'
        source = SourceVersion.find_by_id(source_id)
        return nil unless source
        target = Version.find_by_name_and_project_id(source.name, RedmineMerge::Mapper.get_new_project_id(source.project_id))
        return target.id if target
        return nil
      end
      
    end

    private

    # Utility method to dynamically find the target records
    def self.find_target_record_from_source(source_klass, target_klass, field, source_id)
      
      puts "In find_target_record_from_source source_klass: #{source_klass} target_klass: #{target_klass} field: #{field} source_id: #{source_id}"

      source = source_klass.find_by_id(source_id)
      field = field.to_sym
      if source
        return target_klass.find(:first, :conditions => {field => source.read_attribute(field) })
      else
        return nil
      end
    end
  end
end
