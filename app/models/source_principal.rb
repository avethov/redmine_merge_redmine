class SourcePrincipal < ActiveRecord::Base
    include SecondDatabase
    self.table_name = "users"
end