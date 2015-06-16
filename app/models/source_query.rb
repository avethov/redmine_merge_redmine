class SourceQuery < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'queries'

  belongs_to :user,    class_name: 'SourceUser'
  belongs_to :project, class_name: 'SourceProject'

  def self.find_target(source_query)
    source_query.type.constantize.where(
      project_id: SourceProject.find_target(source_query.project),
      user_id: SourceUser.find_target(source_query.user),
      name: source_query.name
    ).first
  end

  def self.migrate
    all.each do |source_query|
      target_query = SourceQuery.find_target(source_query)
      if target_query
        puts "  Skipping existing #{source_query.type} #{target_query.name}"
        next
      end

      puts "  Migrating #{source_query.type} #{source_query.name}"
      query_klass = source_query.type.constantize
      query_klass.create!(source_query.attributes) do |q|
        q.project = SourceProject.find_target(source_query.project)
        q.user    = SourceUser.find_target(source_query.user)
      end
    end
  end
end
