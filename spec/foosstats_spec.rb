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
    
    8.times { Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 8) }
    5.times { Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 8, :team_two_score => 10) }
  end
  
  it "should redirect to /games/recent when pointed at /" do
    get "/"
    follow_redirect!
    assert_equal "http://example.org/games/recent", last_request.url
    last_response.should be_ok
  end
  
  # Player stats testing
  
  it "should calculate the correct wins and losses" do
    stats = PlayerStats.new
    stats.wins[1].should == 8
    stats.losses[1].should == 5
    stats.wins[3].should == 5
    stats.losses[3].should == 8
  end
  
  it "should calculate the correct streaks" do
    stats = PlayerStats.new
    stats.streaks[1].should == "WWWWWWWWLL"
    stats.streaks[3].should == "LLLLLLLLWW"
  end
  
  it "should calculate the correct win / loss ratios" do
    stats = PlayerStats.new
    stats.ratios[1].should == 1.6
    stats.ratios[3].should == 0.625
  end
  
  it "should find the longest streaks" do
    stats = PlayerStats.new
    stats.longest_wins.should == [8, [1,2]]
    stats.longest_losses.should == [8, [3,4]]
  end
  
end