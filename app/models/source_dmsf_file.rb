# coding: utf-8
class SourceDmsfFile < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'dmsf_files'

  belongs_to :folder, class_name: 'SourceDmsfFolder', foreign_key: 'dmsf_folder_id'
  belongs_to :project, class_name: 'SourceProject', foreign_key: 'project_id'
  belongs_to :user, class_name: 'SourceUser', foreign_key: 'user_id'

  def to_s
    "Dmsf File #{name}"
  end

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceDmsfFile got #{source.class}" unless source.is_a?(SourceDmsfFile)
    DmsfFile.where(
      project_id: SourceProject.find_target(source.project),
      dmsf_folder_id: SourceDmsfFolder.find_target(source.folder),
      name: source.name
    ).first
  end

  def self.migrate
    order(id: :asc).each do |source|
      target = find_target(source)

  	  if !source.project
	    puts "WARN  Skipping dmsf file #{source.name}, missing project"
	    next
	  end

      if target
        puts "  Skipping existing dmsf file #{source.name}"
		next
      end

      puts "  Migrating dmsf file #{source.name} of project #{source.project.name}"
      target = DmsfFile.create!(source.attributes) do |d|
	    d.id = nil
        d.project = SourceProject.find_target(source.project)
        d.folder = SourceDmsfFolder.find_target(source.folder)
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
