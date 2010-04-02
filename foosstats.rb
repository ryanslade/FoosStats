require "rubygems"
require "sinatra"
require "datamapper"
require File.join(File.dirname(__FILE__), "models")

DataMapper.auto_upgrade!

get "/" do
  redirect "/games/recent"
end

get "/players/new" do
  @player_count = Player.count
  erb :players_form
end

post "/players/create" do
  player = Player.create(params)
  if player.save
    redirect "/players"
  else
    redirect "/players/new"
  end
end

get "/players" do
  @players = Player.order_by_name
  @stats = PlayerStats.new
  erb :players
end

get "/games/recent" do
  @games_count = Game.count
  @games = Game.recent
  erb :recent_games
end

get "/games/new" do
  @players = Player.order_by_name
  erb :games
end

post "/games/create" do
  @players = Player.order_by_name
  Game.create!(params)
  redirect "/games/recent"
end

get "/games/assram/:id" do
  Game.get(params[:id]).destroy
  redirect "/games/recent"
end
