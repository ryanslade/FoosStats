require "rubygems"
require "sinatra"
require "models"
require "datamapper"

DataMapper.auto_upgrade!

get "/" do
  redirect "/games/recent"
end

get "/players" do
  before_players
  erb :players
end

post "/players" do
  Player.create!(params)
  before_players
  erb :players
end

get "/games/recent" do
  @games = Game.all(:limit => 10, :order => [ :created_at.desc ])
  erb :recent_games
end

get "/games/new" do
  before_games
  erb :games
end

post "/games/create" do
  before_games
  Game.create!(params)
  redirect "/games/recent"
end

private

def before_games
  @players = Player.all(:order => [ :first_name.asc, :last_name.asc ])
end

def before_players
  @player_count = Player.count
end