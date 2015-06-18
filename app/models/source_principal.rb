class SourcePrincipal < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'users'

  def self.find_target(source)
    return nil unless source
    fail "Expected SourcePrincipal got #{source.class}" unless source.is_a?(SourcePrincipal)
    case source.type
    when 'Group' then SourceGroup.find_target(source.becomes(SourceGroup))
    when 'User' then SourceUser.find_target(source.becomes(SourceUser), fail: false)
    end
  end

  def to_s
    case type
    when 'Group' then "#{lastname}"
    when 'User' then "#{firstname} #{lastname}"
    end
  end
end
