class SourcePrincipal < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'users'

  def self.find_target(source)
    return nil unless source
    case source.type
    when 'Group' then SourceGroup.find_target(source)
    when 'User' then SourceUser.find_target(source, fail: false)
    end
  end
end
