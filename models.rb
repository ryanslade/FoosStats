require "datamapper"

DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/stats.db")
DataMapper.auto_migrate!

class Player
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :created_at, DateTime, :default => Proc.new { Time.now }
  
  property :first_name, String
  property :last_name, String
  property :email, String    
end

class Game
  include DataMapper::Resource
  
  property :id, Serial, :key => true
  property :created_at, DateTime, :default => Proc.new { Time.now }
  
  property :team_one_attack, Integer
  property :team_one_defense, Integer
  property :team_one_score, Integer, :default => 0
  
  property :team_two_attack, Integer
  property :team_two_defense, Integer
  property :team_two_score, Integer, :default => 0
end