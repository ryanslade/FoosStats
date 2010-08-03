require File.dirname(__FILE__) + '/spec_helper'

describe "Player Statistics" do
  def app
    @app ||= Sinatra::Application
  end

  before(:all) do
    setup_db
  end

  it "should should allow player stats to be created with 1, 2 or no players" do
    lambda { PlayerStats.new(:players => [1,3]) }.should_not raise_error(error)
    lambda { PlayerStats.new() }.should_not raise_error(error)
    lambda { PlayerStats.new(:players => [1]) }.should_not raise_error(StandardError)
    lambda { PlayerStats.new(:players => [1,2,3]) }.should raise_error(StandardError)
  end

  it "should only bring back stats for 2 players only" do
    stats = PlayerStats.new(:players => [1,3])
    stats.played[1].should == 15
    stats.played[2].should == 13
    stats.played[3].should == 15
    stats.played[4].should == 15
  end

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

  it "should calculate the correct recent streaks" do
    stats = PlayerStats.new
    stats.streaks[1].recent.should == "WHLLLLLWWW"
    stats.streaks[2].recent.should == "LLLLLWWWWW"
    stats.streaks[3].recent.should == "LWWWWWWLLL"
    stats.streaks[4].recent.should == "LWWWWWWLLL"
    stats.streaks[5].recent.should == ""
  end

  it "should calculate the correct overall streaks" do
    stats = PlayerStats.new
    stats.streaks[1].all.should == "WHLLLLLWWWWWWWW"
    stats.streaks[2].all.should == "LLLLLWWWWWWWW"
    stats.streaks[3].all.should == "LWWWWWWLLLLLLLL"
    stats.streaks[4].all.should == "LWWWWWWLLLLLLLL"
    stats.streaks[5].all.should == ""
  end

  it "should calculate the longest streaks per player" do
    stats = PlayerStats.new
    stats.streaks[1].longest_win.should == 8
    stats.streaks[2].longest_win.should == 8
    stats.streaks[3].longest_win.should == 6
    stats.streaks[4].longest_win.should == 6
    stats.streaks[5].longest_win.should == 0

    stats.streaks[1].longest_loss.should == 6
    stats.streaks[2].longest_loss.should == 5
    stats.streaks[3].longest_loss.should == 8
    stats.streaks[4].longest_loss.should == 8
    stats.streaks[5].longest_loss.should == 0
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
    stats.average_goals_scored[1].to_s.should == "8.86666666666667"
  end

  it "should recored the average goals conceded when in defense" do
    stats = PlayerStats.new
    stats.average_goals_conceded[2].should == 8.76923076923077
  end

  it "should record each players most popular teammate" do
    stats = PlayerStats.new
    stats.most_popular_teammates[1].should == [2]
    stats.most_popular_teammates[2].should == [1]
    stats.most_popular_teammates[3].should == [4]
    stats.most_popular_teammates[4].should == [3]
  end

  it "should record each players most popular opponents" do
    stats = PlayerStats.new
    stats.most_popular_opponents[1].should == [3,4]
    stats.most_popular_opponents[2].should == [3,4]
    stats.most_popular_opponents[3].should == [1]
    stats.most_popular_opponents[4].should == [1]
  end

  it "should bring back the same results no matter what the order of the vs" do
    stats = PlayerStats.new(:players => [1,3])
    stats.ratios[1].should == 9.0/6
    stats.ratios[3].should == 6.0/9
    stats = PlayerStats.new(:players => [3,1])
    stats.ratios[1].should == 9.0/6
    stats.ratios[3].should == 6.0/9
  end

  it "should calculate the percentage of games lost with less than 5" do
    stats = PlayerStats.new
    stats.humiliation_percentage[1].to_s.should == "6.66666666666667"
  end
  
  it "should calulate the wins percentage" do
    stats = PlayerStats.new
    stats.wins_percentage[1].should == (9.to_f/15)*100
  end
  
end
