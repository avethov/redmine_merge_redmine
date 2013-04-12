class SourceNews < ActiveRecord::Base
  include SecondDatabase
  set_table_name :news

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'
  # Added by KS
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'

  def self.migrate
    all.each do |source_news|
      puts "source_news project = #{source_news.project.name}, author = #{source_news.author.login}"

      # KS - you have to set the project and author before creating the new news event due to foreign 
      #      key constraints.  Note that you have to just assign the ID not the class (e.g., author_id rather than author)
      source_news.project_id = RedmineMerge::Mapper.get_new_project_id(source_news.project.id)
      
      puts "  Source author_id: #{source_news.author_id} source author login: #{source_news.author.login}"
      author_tmp = User.find_by_login(source_news.author.login)
      source_news.author_id = author_tmp.id
      puts "  Merged author_id: #{source_news.author_id}"
      puts "  Merged project_id: #{source_news.project_id}"
            
      news = News.create!(source_news.attributes)

      puts "  source id: #{source_news.id}"      
      puts "  migrated id: #{news.id}"      
      # Added by KS - need to have the mapping for attachments
      RedmineMerge::Mapper.add_news(source_news.id, news.id)
    end
  end
end
