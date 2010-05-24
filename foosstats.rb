require "rubygems"
require "sinatra"
require "datamapper"
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
  @stats = PlayerStats.new
  @players = Player.order_by_name
  @sorted_players = @players.sort { |a, b| @stats.ratios[a.id] <=> @stats.ratios[b.id] }.reverse
  erb :players
end

get "/games/recent" do
  @games_count = Game.count
  @games = Game.recent
  erb :recent_games
end

get "/games/new" do
  @game = Game.new # Empty game so that the view works for /new and /another
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

helpers do
  def streaks_to_images(streak)
    beer = "/images/icon_beer.gif"
    turd = "/images/icon_turd.gif"
    streak = streak.gsub("W", image(beer))
    streak = streak.gsub("L", image(turd))
    streak
  end
  
  def image(url)
    "<img src='#{url}' />"
  end
  
  def format_most_popular(popular)
    popular ? popular.collect { |p| @players.get(p).name }.join(", ") : ""
  end
end

