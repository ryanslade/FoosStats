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
  player = Player.create(params)
  if player.save
    erb :player_form
  else
    redirect "/players"
  end
end

get "/players" do
  @players = Player.order_by_name
  @stats = PlayerStats.new
  erb :players
end

get "/games/recent" do
  @games = Game.recent
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

get "/games/assram/:id" do
  Game.get(params[:id]).destroy
  redirect "/games/recent"
end

private

def before_games
  @players = Player.order_by_name
end

def before_players
  @player_count = Player.count
end