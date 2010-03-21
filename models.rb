require "datamapper"

class Player
  include DataMapper::Resource
  
  property :id, Serial
  property :first_name, String
  property :last_name, String
  property :email, String
  property :created_at, DateTime, :default => Proc.new { Time.now } 
end
