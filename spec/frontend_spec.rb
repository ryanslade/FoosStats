require File.dirname(__FILE__) + '/spec_helper'

describe "Integration" do
  include Rack::Test::Methods
  
  def app
    @app ||= Sinatra::Application
  end

  before :all do
    setup_db
  end
    
  it "should redirect to /players when pointed at /" do
    get "/"
    follow_redirect!
    last_request.url.should == "http://example.org/players"
    last_response.should be_ok
  end

  it "should should bring back more recent games if path is /games/recent/:limit" do
    get "/games/recent"
    last_response.should be_ok
    last_response.body.scan(/<tr>/).length.should == Game.recent.length+1
    
    get "/games/recent/5"
    last_response.should be_ok
    last_response.body.scan(/<tr>/).length.should == 6
    
    get "/games/recent/all"
    last_response.should be_ok
    last_response.body.scan(/<tr>/).length.should == Game.count+1
  end

  it "should create a new game when posted to /games/create" do
    before_count = Game.count
    begin
      post "/games/create", params = {:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 8}
      Game.count.should == before_count+1
      follow_redirect!
      last_request.url.should == "http://example.org/games/recent"
      last_response.should be_ok
      last_response.body.include?("Game was succesfully created").should be_true
    ensure
      Game.last.destroy if Game.count > before_count
    end
  end

  it "should should create a new player when posted to /players/create" do
    before_count = Player.count
    begin
      post "/players/create", params = {:first_name => "firstname", :last_name => "lastname", :email => "testemail@test.com"}
      Player.count.should == before_count+1
      follow_redirect!
      last_request.url.should == "http://example.org/players"
      last_response.should be_ok
      last_response.body.include?("Player was succesfully created").should be_true
    ensure
      Player.last.destroy if Player.count > before_count
    end
  end

  it "should show user specific details from /players/:playerid" do
    player = Player.get(1)
    get "/players/1"
    last_response.should be_ok
    last_response.body.include?(player.name).should be_true
  end
  
  # Versus stuff

  it "should redirect to /players/a/vs/b when posted to" do
    post "/players/vs", params = {:player_one => 1, :player_two => 3}
    follow_redirect!
    last_request.url.should == "http://example.org/players/1/vs/3"
    last_response.should be_ok
  end

  it "should respond to /players/a/vs/b" do
    get "/players/1/vs/3"
    last_request.url.should == "http://example.org/players/1/vs/3"
    last_response.should be_ok
  end
  
  # Match stuff
  it "should bring back all games without an associated match" do
    get "/matches/manage"
    last_response.should be_ok
    last_response.body.scan(/<tr>/).length.should == 13
  end
  
  # Delete game
  it "should delete a game when posted to /games/delete/x" do
    old_count = Game.count
    g = Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 8)
    post "/games/delete/#{g.id}"
    Game.count.should == old_count
    follow_redirect!
    last_request.url.should == "http://example.org/games/recent"
    last_response.should be_ok
  end
    
end