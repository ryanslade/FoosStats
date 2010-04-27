require "rubygems"
require "sinatra"
require "datamapper"
require "less"
require "rack-flash"

require File.join(File.dirname(__FILE__), "models")

DataMapper.auto_upgrade!

set :sessions, true
use Rack::Flash

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
    flash[:notice] = "Player was succesfully created"
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
  @game = Game.new
  @players = Player.order_by_name
  erb :games
end

get "/games/another" do
  @game = Game.last
  @players = Player.order_by_name
  erb :games
end

post "/games/create" do
  game = Game.create(params)
  if game.save
    flash[:notice] = "Game was succesfully created"
    redirect "/games/recent"
  else
    redirect "/games/new"
  end
end

get "/games/assram/:id" do
  Game.get(params[:id]).destroy
  redirect "/games/recent"
end

get "/stylesheet.css" do
  content_type "text/css", :charset => "utf-8"
  less :stylesheet
end
