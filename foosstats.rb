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

get '/players/vs' do
  setup_stats_view(:view => :choosevs)
end

post '/players/vs' do
  redirect "/players/#{params[:player_one]}/vs/#{params[:player_two]}"
end

get "/players/*/vs/*" do
  player_ids = params[:splat].collect { |p| p.to_i }
  @players = Player.all(:id => player_ids)
  @stats = PlayerStats.new(@players.collect { |p| p.id })
  @sorted_players = @players.sort { |a, b| @stats.ratios[a.id] <=> @stats.ratios[b.id] }.reverse
  erb :playervs
end

get "/games/recent" do
  get_recent_games
end

get "/games/recent/all" do
  get_recent_games(:all)
end

get "/games/recent/:limit" do
  get_recent_games(params[:limit].to_i)
end

def get_recent_games(limit=nil)
  @games_count = Game.count
  @games = limit ? Game.recent(limit) : Game.recent
  erb :recent_games
end

get "/games/new" do
  setup_stats_view
end

get "/games/another" do
  setup_stats_view(:game => Game.last)
end

def setup_stats_view(options={})
  options[:game] ||= Game.new
  options[:view] ||= :games
  @game = options[:game]
  @players = Player.order_by_name
  erb options[:view]
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
