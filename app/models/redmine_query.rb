# Created by Ken Sperow -- there is a Query class in Redmine's model but I can't access it because 
#      the following Query class is found:  ActiveRecord::AttributeMethods::Query:Module
#
#  I get the following error when trying to use Redmine's class
#   undefined method `create!' for ActiveRecord::AttributeMethods::Query:Module

class RedmineQuery < ActiveRecord::Base
  self.table_name = "queries"
    
  belongs_to :project
  belongs_to :user
end