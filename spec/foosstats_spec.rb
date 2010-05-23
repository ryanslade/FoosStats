require File.dirname(__FILE__) + '/spec_helper'

describe "Foos Stats" do
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  before(:all) do
    DataMapper.auto_migrate!
    4.times do |n|
      Player.create(:first_name => "first#{n}", :last_name => "last#{n}", :email => "test#{n}@test.com")
    end

    # Edge case player
    Player.create(:first_name => "first", :last_name => "last", :email => "test@test.com")

    8.times { Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 8) }
    5.times { Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 8, :team_two_score => 10) }
    
    # Same player can be on one team
    Game.create(:team_one_attack => 1, :team_one_defense => 1, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 8, :team_two_score => 10)
    Game.create(:team_one_attack => 1, :team_one_defense => 1, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 8)
  end

  # Integration testing

  it "should redirect to /games/recent when pointed at /" do
    get "/"
    follow_redirect!
    last_request.url.should == "http://example.org/games/recent"
    last_response.should be_ok
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
  
  # Game testing

  it "should should validate that players have been added" do
    g = Game.new(:team_one_attack => 1, :team_two_attack => 3, :team_one_defense => 2, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 5)
    g.valid?.should be true

    g = Game.new(:team_one_attack => 0, :team_two_attack => 3, :team_one_defense => 2, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 5)
    g.valid?.should be false
  end

  it "should should validate that at least one team has 10" do
    g = Game.new(:team_one_attack => 1, :team_two_attack => 3, :team_one_defense => 2, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 5)
    g.valid?.should be true

    g = Game.new(:team_one_attack => 1, :team_two_attack => 3, :team_one_defense => 2, :team_two_defense => 4, :team_one_score => 6, :team_two_score => 5)
    g.valid?.should be false
  end

  it "should ensure that a player cannot be on both teams" do
    g = Game.new(:team_one_attack => 1, :team_two_attack => 1, :team_one_defense => 2, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 5)
    g.valid?.should be false
  end

  # Player stats testing

  it "should calculate the correct wins and losses" do
    stats = PlayerStats.new
    stats.wins[1].should == 9
    stats.losses[1].should == 6
    stats.played[1].should == 15
    stats.wins[2].should == 8
    stats.losses[2].should == 5
    stats.played[2].should == 13
    
    stats.wins[3].should == 6
    stats.losses[3].should == 9
    stats.played[3].should == 15
    stats.wins[4].should == 6
    stats.losses[4].should == 9
    stats.played[4].should == 15
    
    stats.wins[5].should == 0
    stats.losses[5].should == 0
    stats.played[5].should == 0
  end

  it "should calculate the correct streaks" do
    stats = PlayerStats.new
    stats.streaks[1].should == "WLLLLLLWWW"
    stats.streaks[2].should == "LLLLLWWWWW"
    stats.streaks[3].should == "LWWWWWWLLL"
    stats.streaks[4].should == "LWWWWWWLLL"
    stats.streaks[5].should == ""
  end

  it "should calculate the correct win / loss ratios" do
    stats = PlayerStats.new
    stats.ratios[1].should == (9.0/6)
    stats.ratios[3].should == (6.0/9)
    stats.ratios[5].should == 0
  end

  it "should find the longest streaks" do
    stats = PlayerStats.new
    stats.longest_wins.should == [8, [1,2]]
    stats.longest_losses.should == [8, [3,4]]
  end

  it "should record the average goals scored when in attack" do
    stats = PlayerStats.new
    stats.average_goals_scored[1].should == 9.2
  end

  it "should recored the average goals conceded when in defense" do
    stats = PlayerStats.new
    stats.average_goals_conceded[2].should == 8.76923076923077
  end

  it "should record each players most popular teammate" do
    stats = PlayerStats.new
    stats.most_popular_teammate[1].should == [2]
    stats.most_popular_teammate[2].should == [1]
    stats.most_popular_teammate[3].should == [4]
    stats.most_popular_teammate[4].should == [3]
  end
  
  it "should record each players most popular opponents" do
    stats = PlayerStats.new
    stats.most_popular_opponent[1].should == [3,4]
    stats.most_popular_opponent[2].should == [3,4]
    stats.most_popular_opponent[3].should == [1]
    stats.most_popular_opponent[4].should == [1]
  end
  
end
