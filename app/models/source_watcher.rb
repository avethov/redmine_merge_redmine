# Added by Ken Sperow
# Depends on user and watchable_id, which can point to an issue, wiki_page, or news



class SourceWatcher < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "watchers"

  belongs_to :watchable, :polymorphic => true
  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'


  def self.migrate
    all.each do |source_watcher|

      puts "migrating watcher, source_watcher.id: #{source_watcher.id}"
      puts "  source_watcher.watchable_type: #{source_watcher.watchable_type}"
      puts "  source_watcher.watchable_id: #{source_watcher.watchable_id}"
      puts "  source_watcher.user.login: #{source_watcher.user.login}"
      
      # Moved these above because validation required them to be set properly when creating the migrated watcher
      # as opposed to doing this in the do block
      temp_user = User.find_by_login(source_watcher.user.login)
      source_watcher.user_id = temp_user.id
      
      # In VLab thus far we are not dealing with messages (so skip them if there happen to be any)
      next if source_watcher.watchable_type == "Message"
      
      source_watcher.watchable = case source_watcher.watchable_type
                    when "Issue"
                      Issue.find RedmineMerge::Mapper.get_new_issue_id(source_watcher.watchable_id)
                    when "Document"
                      Document.find RedmineMerge::Mapper.get_new_document_id(source_watcher.watchable_id)
                    when "WikiPage"
                      WikiPage.find RedmineMerge::Mapper.get_new_wiki_page_id(source_watcher.watchable_id)
                    when "Project"
                      Project.find RedmineMerge::Mapper.get_new_project_id(source_watcher.watchable_id)
                    when "Version"
                      Version.find RedmineMerge::Mapper.get_new_version_id(source_watcher.watchable_id)
                    when "News"
                      News.find RedmineMerge::Mapper.get_new_news_id(source_watcher.watchable_id)
                    end

      puts "  merged_watcher.watchable_type: #{source_watcher.watchable_type}"
      puts "  merged_watcher.watchable_id: #{source_watcher.watchable_id}"
      puts "  merged_watcher.user.login: #{temp_user.login}"

      # Don't migrate watcher entries for News events where the News author is the watcher
      if !((source_watcher.watchable_type == "News") && (source_watcher.watchable.author.login == temp_user.login))
        Watcher.create!(source_watcher.attributes)
      end
    end
  end
end