# coding: utf-8
class SourceDmsfFileRevision < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'dmsf_file_revisions'

  belongs_to :file, class_name: 'SourceDmsfFile', foreign_key: 'dmsf_file_id'
  belongs_to :source_revision, class_name: 'SourceDmsfFileRevision', foreign_key: 'source_dmsf_file_revision_id'
  belongs_to :user, class_name: 'SourceUser', foreign_key: 'user_id'
  belongs_to :deleted_by_user, class_name: 'SourceUser', foreign_key: 'deleted_by_user_id'

  def to_s
    "Dmsf File Revision #{name} #{major_version}.#{minor_version}"
  end

  def self.find_target(source)
    return nil unless source
    fail "Expected SourceDmsfFileRevision got #{source.class}" unless source.is_a?(SourceDmsfFileRevision)
    DmsfFileRevision.where(
      dmsf_file_id: SourceDmsfFile.find_target(source.file),
	  major_version: source.major_version,
	  minor_version: source.minor_version
    ).first
  end

  def self.migrate
    order(id: :asc).each do |source|
      target = find_target(source)

      if target
        puts "  Skipping existing dmsf file #{source.name}"
		next
      end

      puts "  Migrating dmsf file #{source.name} revision #{source.major_version}.#{source.minor_version}"
      target = DmsfFileRevision.create!(source.attributes) do |d|
	    d.id = nil
		d.file = SourceDmsfFile.find_target(source.file)
		d.source_revision = SourceDmsfFileRevision.find_target(source.source_revision) if source.source_revision
		d.user = SourceUser.find_target(source.user)
		d.deleted_by_user = SourceUser.find_target(source.deleted_by_user) if source.deleted_by_user
      end

      RedmineMerge::Mapper.map(source, target)
    end
  end
end
