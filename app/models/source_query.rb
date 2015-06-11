class SourceQuery < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "queries"

  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'

  def self.find_target(source_query)
    project = SourceProject.find_target(source_query.project)
    user = SourceUser.find_target(source_query.user)
    ::Query.first(:conditions => {
                    :project_id => project,
                    :user_id => user,
                    :name => source_query.name
                  })
  end

  def self.migrate
    all.each do |source_query|
      target_query = SourceQuery.find_target(source_query)
      if target_query
        puts "  Skipping existing query #{target_query.name}"
        next
      end

      puts "Migrating query #{source_query.name}"
      ::Query.create!(source_query.attributes) do |q|
        q.project = SourceProject.find_target(source_query.project)
        q.user = SourceUser.find_target(source_query.user)
      end
    end
  end
end
