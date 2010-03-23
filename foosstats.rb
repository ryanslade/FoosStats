require "rubygems"
require "sinatra"
require "datamapper"
require File.join(File.dirname(__FILE__), "models")

DataMapper.auto_upgrade!

get "/" do
  redirect "/games/recent"
end

get "/players/new" do
  before_players
  erb :players_form
end

post "/players/create" do
  Player.create!(params)
  before_players
  erb :players_form
end

get "/players" do
  @players = Player.order_by_name
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
  @players = Player.order_by_name
end

def before_players
  @player_count = Player.count
end