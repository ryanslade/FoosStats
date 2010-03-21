require "datamapper"

DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/stats.db")
DataMapper.auto_migrate!

class Player
  include DataMapper::Resource
  
  property :id, Serial, :key => true 
  property :first_name, String
  property :last_name, String
  property :email, String
  property :created_at, DateTime, :default => Proc.new { Time.now }
end
