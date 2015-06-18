class SourceQuery < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'queries'

  belongs_to :user,    class_name: 'SourceUser'
  belongs_to :project, class_name: 'SourceProject'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceQuery got #{source.class}" unless source.is_a?(SourceQuery)
    source.type.constantize.where(
      project_id: SourceProject.find_target(source.project),
      user_id: SourceUser.find_target(source.user),
      name: source.name
    ).first
  end

  def self.migrate
    all.each do |source|
      target_query = SourceQuery.find_target(source)
      if target_query
        puts "  Skipping existing #{source.type} #{target_query.name}"
        next
      end

      puts "  Migrating #{source.type} #{source.name}"
      query_klass = source.type.constantize
      query_klass.create!(source.attributes) do |q|
        q.project = SourceProject.find_target(source.project)
        q.user    = SourceUser.find_target(source.user)
      end
    end
  end
end
