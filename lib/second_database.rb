# Abstraction to connect to the second database
module SecondDatabase
  def self.included(base)
    base.class_eval do
      establish_connection :source_redmine
      self.inheritance_column = :_type_disabled
    end
  end
end
