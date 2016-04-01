class SourceIssuePriority < SourceEnumeration
  def self.migrate
    migrate_enum('IssuePriority')
  end
end