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
    
    10.times { Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 8) }
    5.times { Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 8, :team_two_score => 10) }
  end
  
  it "should redirect to /games/recent when pointed at /" do
    get "/"
    follow_redirect!
    assert_equal "http://example.org/games/recent", last_request.url
    last_response.should be_ok
  end
end