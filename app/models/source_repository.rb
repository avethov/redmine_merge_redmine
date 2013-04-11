class SourceRepository < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "repositories"

  def self.migrate
    all.each do |source_repository|

      Repository::Git.create!(source_repository.attributes) do |d|
        d.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_repository.project_id))
#        d.type = source_repository.type
      end
    end
  end
end