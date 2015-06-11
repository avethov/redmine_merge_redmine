class SourceRepository < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'repositories'

  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'

  def self.find_target(source_repo)
    target_url     = source_repo.url
    target_project = SourceProject.find_target(source_repo.project)
    Repository.find_by_url_and_project_id(target_url, target_project.id)
  end

  def self.migrate
    all.each do |source_repo|
      if source_repo.project.nil?
        puts "  Skipping #{source_repo.url}, because project ref is `nil`"
        next
      end

      target_repo = SourceRepository.find_target(source_repo)

      if target_repo
        puts "  Skipping existing repository #{source_repo.url}"
        next
      end

      repo_klass = source_repo.type.constantize
      # Make sure the validations for enabled repo types pass.
      Setting.enabled_scm =
        Setting.enabled_scm.push(repo_klass.name.demodulize).uniq

      puts "  Migrating repository #{source_repo.url} for project #{source_repo.project.name}"
      repo_klass.create!(source_repo.attributes) do |d|
        d.project = SourceProject.find_target(source_repo.project)
      end
    end
  end
end
