require "rubygems"
require "sinatra"
require "datamapper"
require "models"

DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/stats.db")
DataMapper.auto_migrate!

get '/' do
  erb :index
end

