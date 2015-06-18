class SourceNews < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'news'

  belongs_to :author,  class_name: 'SourceUser'
  belongs_to :project, class_name: 'SourceProject'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceNews got #{source.class}" unless source.is_a?(SourceNews)
    News.where(
      author_id:  SourceUser.find_target(source.author),
      project_id: SourceProject.find_target(source.project),
      title: source.title
    ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)
      if target
        puts "  Skipping existing news #{target.title} by #{target.author}"
        next
      end

      puts "  Migrating news: #{source.title} by #{source.author}"
      target = News.create!(source.attributes) do |n|
        n.author  = SourceUser.find_target(source.author)
        n.project = SourceProject.find_target(source.project)
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
