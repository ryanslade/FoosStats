require "rubygems"
require "sinatra"
require "models"

get "/" do
  erb :index
end

get "/users/new" do
  erb :new_user
end

post "/add_user" do
  Player.create(params)
end