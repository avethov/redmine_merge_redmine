class SourceNews < ActiveRecord::Base
  include SecondDatabase
  set_table_name :news

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'
  # Added by KS
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'

  def self.migrate
    all.each do |source_news|
      puts "source_news project = #{source_news.project.name}, author = #{source_news.author.login}"
      # KS - get the project and author before creating the record
#      project_tmp = Project.find(RedmineMerge::Mapper.get_new_project_id(source_news.project.id))
#      author_tmp = User.find_by_login(source_news.author.login)
#      puts "Merged author = #{author_tmp.login}" if author_tmp
#      puts "Merged project = #{project_tmp.name}" if project_tmp
#      source_news_copy = source_news
      # The following does not work because the classes are different (e.g., SourceProject versus Project)
#      source_news_copy.project = project_tmp
#      source_news_copy.author = author_tmp

      # KS - you have to set the project and author before creating the new news event due to foreign 
      #      key constraints.  Note that you have to just assign the ID not the class (e.g., author_id rather than author)
      source_news.project_id = RedmineMerge::Mapper.get_new_project_id(source_news.project.id)
      author_tmp = User.find_by_login(source_news.author.login)
      source_news.author_id = author_tmp.id
      puts "Merged author_id = #{source_news.author_id}"
      puts "Merged project_id = #{source_news.project_id}"
            
      news = News.create!(source_news.attributes) do |n|
#        n.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_news.project_id))
#        n.author = User.find_by_login(source_news.author.login)
      end
      
      # Added by KS - need to have the mapping for attachments
      RedmineMerge::Mapper.add_news(source_news.id, news.id)
    end
  end
end
