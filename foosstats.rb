require "rubygems"
require "sinatra"
require "models"

get "/" do
  erb :index
end

get "/players" do
  before_players
  erb :players
end

post "/players" do
  Player.create(params)
  before_players
  erb :players
end

private

def before_players
  @player_count = Player.count
end