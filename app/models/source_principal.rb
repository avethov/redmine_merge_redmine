class SourcePrincipal < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'users'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourcePrincipal got #{source.class}" unless source.is_a?(SourcePrincipal)
    case source.type
    when 'Group' then SourceGroup.find_target(source)
    when 'User' then SourceUser.find_target(source, fail: false)
    end
  end
end
