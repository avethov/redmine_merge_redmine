class SourceEnabledModule < ActiveRecord::Base
  include SecondDatabase
  self.table_name = 'enabled_modules'

end
