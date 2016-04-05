# coding: utf-8
class SourceDmsfFolder < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'dmsf_folders'

  belongs_to :parent, class_name: 'SourceDmsfFolder', foreign_key: 'dmsf_folder_id'
  belongs_to :project, class_name: 'SourceProject', foreign_key: 'project_id'
  belongs_to :user,  class_name: 'SourceUser', foreign_key: 'user_id'

  def to_s
    "Dmsf Folder #{title}"
  end

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceDMSFFolder got #{source.class}" unless source.is_a?(SourceDmsfFolder)
    DmsfFolder.where(
      project_id: SourceProject.find_target(source.project),
      dmsf_folder_id: SourceDmsfFolder.find_target(source.parent),
      title: source.title
    ).first
  end

  def self.migrate
    order(id: :asc).each do |source|
      target = find_target(source)

      if target
        puts "  Skipping existing dmsf folder #{source.title}"
		next
      end

      puts "  Migrating dmsf folder #{source.project.name} #{source.title}"
      target = DmsfFolder.create!(source.attributes) do |d|
	    d.id = nil
        d.project = SourceProject.find_target(source.project)
        d.folder = SourceDmsfFolder.find_target(source.parent)
        d.user = SourceUser.find_target(source.user)
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
