class SourceQuery < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "queries"

  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'

  def self.migrate
    all.each do |source_query|
      
# Unable to use just Query because the wrong class is found
#      Query.create!(source_query.attributes) do |q|
      RedmineQuery.create!(source_query.attributes) do |q|
        q.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_query.project_id))
        q.user = User.find_by_login(source_query.user.login)
        puts "migrated query, source_query.user.login: #{source_query.user.login}  migrated_user.login: #{q.user.login}"
      end
    end
  end
end
