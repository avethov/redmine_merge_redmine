class SourceTimeEntryActivity < SourceEnumeration
  def self.migrate
    migrate_enum('TimeEntryActivity')
  end
end