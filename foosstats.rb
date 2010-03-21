require "rubygems"
require "sinatra"
require "models"

get "/" do
  erb :index
end

get "/players" do
  @player_count = Player.count
  erb :players
end

post "/players" do
  Player.create(params)
  @player_count = Player.count
  erb :players
end