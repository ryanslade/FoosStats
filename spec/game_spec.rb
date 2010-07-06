require File.dirname(__FILE__) + '/spec_helper'

describe "Game" do
  def app
    @app ||= Sinatra::Application
  end

  before :all do
    setup_db
  end
  
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

  it "should bring back only games with the two players opposite each other" do
    Game.versus([1,3]).length.should == 15
    Game.versus([1,2]).length.should == 0
  end

  it "should should bring back games where specific player was involved" do
    Game.with_player(1).length.should == 15
    Game.with_player(2).length.should == 13
  end

  it "should limit recent games to 10 by default" do
    Game.recent.length.should == 10
  end
  
  it "should limit recent games" do
    Game.recent(5).length.should == 5
    Game.recent(:all).length.should == 15
  end
  
end