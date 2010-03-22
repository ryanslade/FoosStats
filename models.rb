require "datamapper"

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/stats.db")

class Player
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :created_at, DateTime, :default => lambda { Time.now }
  
  property :first_name, String
  property :last_name, String
  property :email, String
  
  def name
    "#{first_name} #{last_name}"
  end
end

class Game
  include DataMapper::Resource
  
  property :id, Serial, :key => true
  property :created_at, DateTime, :default => lambda { Time.now }
  
  property :team_one_attack, Integer
  property :team_one_defense, Integer
  property :team_one_score, Integer, :default => 0
  
  belongs_to :team_one_attacker, Player, :child_key => [:team_one_attack]
  belongs_to :team_one_defender, Player, :child_key => [:team_one_defense]
  
  property :team_two_attack, Integer
  property :team_two_defense, Integer
  property :team_two_score, Integer, :default => 0
  
  belongs_to :team_two_attacker, Player, :child_key => [:team_two_attack]
  belongs_to :team_two_defender, Player, :child_key => [:team_two_defense]
end