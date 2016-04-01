class SourceDocumentCategory < SourceEnumeration
  def self.migrate
    migrate_enum('DocumentCategory')
  end
end