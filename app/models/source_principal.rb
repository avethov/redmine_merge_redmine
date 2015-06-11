class SourcePrincipal < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "users"

  def self.find_target(source_principal, options = { fail: true })
    target = User.find_by_mail(source_principal.mail) || User.find_by_login(source_principal.login)
    if target.nil? && options[:fail]
      fail "No target found with mail `#{source_principal.mail}` or login `#{source_principal.login}`"
    end
    target
  end
end
