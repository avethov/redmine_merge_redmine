class SourceUserPreference < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "user_preferences"

  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'

  def self.migrate
    all.each do |source_user_preference|
      
      UserPreference.create!(source_user_preference.attributes) do |p|
        p.user = User.find_by_login(source_user_preference.user.login)
        puts "migrated user_preference, source_user_preference.user.login: #{source_user_preference.user.login}  migrated_user.login: #{p.user.login}"
      end
    end
  end
end
