require "rubygems"
require "sinatra"
require "models"
require "datamapper"

DataMapper.auto_upgrade!

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

get "/games" do
  before_games
  erb :games
end

post "/games" do
  before_games
  Game.create(params)
  erb :games
end

private

def before_games
  @players = Player.all(:order => [ :first_name.asc, :last_name.asc ])
end

def before_players
  @player_count = Player.count
end