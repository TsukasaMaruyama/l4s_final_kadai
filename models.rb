require 'bundler/setup'
Bundler.require

if development?
  ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end

class Mokmok < ActiveRecord::Base
     has_many :participate_users
end

class ParticipateUser < ActiveRecord::Base
     belongs_to :mokmok
end
