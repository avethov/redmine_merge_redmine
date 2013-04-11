class SourceRepository < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "repositories"

  def self.migrate
    all.each do |source_repository|

      # Note the use of Repository::Git, which sets the type properly.  If we had any other types of repositories in our DB a check would need
      # to be placed here
      Repository::Git.create!(source_repository.attributes) do |d|
        d.project = Project.find(RedmineMerge::Mapper.get_new_project_id(source_repository.project_id))
      end
    end
  end
end