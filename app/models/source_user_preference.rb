# coding: utf-8
class SourceUserPreference < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "user_preferences"

  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'

  def self.real_user_preferences
    joins(:user).all(:conditions => { :users => { :type => "User" } })
  end

  def target_exists?
    target_user = SourceUser.find_target(user)
    UserPreference.exists?(user_id: target_user.id)
  end

  def self.migrate
    real_user_preferences.each do |source_user_preference|
      if source_user_preference.target_exists?
        puts "  Skipping existing preference for #{source_user_preference.user}"
        next
      end

      UserPreference.create!(source_user_preference.attributes) do |p|
        mail  = source_user_preference.user.mail
        login = source_user_preference.user.login

        p.user = SourceUser.find_target(source_user_preference.user)

        puts <<LOG
  Migrated user_preference for #{source_user_preference.user}
    source login: #{login}
    source mail: #{mail}
    target login: #{p.user.login}
    target mail: #{p.user.mail}
LOG
      end
    end
  end
end
