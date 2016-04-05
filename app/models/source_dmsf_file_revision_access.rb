# coding: utf-8
class SourceDmsfFileRevisionAccess < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'dmsf_file_revision_accesses'

  belongs_to :revision, class_name: 'SourceDmsfFileRevision', foreign_key: 'dmsf_file_revision_id'
  belongs_to :user, class_name: 'SourceUser', foreign_key: 'user_id'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceDmsfFileRevisionAccess got #{source.class}" unless source.is_a?(SourceDmsfFileRevisionAccess)
    DmsfFileRevisionAccess.where(
      dmsf_file_revision_id: SourceDmsfFileRevision.find_target(source.revision),
	  user_id: SourceUser.find_target(source.user)
    ).first
  end

  def self.migrate
    all.each do |source|
	  # quality check if user or revision does not exist anymore in db
	  if !source.revision || !source.user
        puts "  Skipping existing dmsf file access id #{source.id}, invalid user or revision"
		next
	  end

      target = find_target(source)

      if target
        puts "  Skipping existing dmsf file access id #{source.id}"
		next
      end

	  rev = source.revision
      puts "  Migrating dmsf file revision access #{rev.name} revision #{rev.major_version}.#{rev.minor_version}"
      target = DmsfFileRevisionAccess.create!(source.attributes) do |d|
	    d.id = nil
		d.revision = SourceDmsfFileRevision.find_target(rev)
		d.user = SourceUser.find_target(source.user)
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
