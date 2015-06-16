# coding: utf-8
class SourceDocument < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'documents'

  belongs_to :category, class_name: 'SourceEnumeration'
  belongs_to :project,  class_name: 'SourceProject'

  def self.find_target(source)
    Document.find_by_id(RedmineMerge::Mapper.target_id(source)) ||
      Document.where(
        project_id: SourceProject.find_target(source.project),
        title: source.title
      ).first
  end

  def self.migrate
    all.each do |source|
      target = find_target(source)

      if target
        puts "  Skipping existing document #{source.title}"
      else
        puts "  Migrating document #{source.title}"
        target = Document.create!(source.attributes) do |d|
          d.project = SourceProject.find_target(source.project)
          d.category = SourceEnumeration.find_target(source.category)
        end
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
