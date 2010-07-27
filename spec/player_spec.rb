require File.dirname(__FILE__) + '/spec_helper'

describe "Player" do
  include Rack::Test::Methods
  
  def app
    @app ||= Sinatra::Application
  end

  before :all do
    setup_db
  end
  
  it "should allow a players profile to use markdown" do
    player = Player.get(1)
    player.description.should == "\n"
    player.description = "Test *markdown*"
    player.save
    player.description.should == "<p>Test <em>markdown</em></p>\n"
    player.raw_description.should == "Test *markdown*"
  end

  it "should update a players description" do
    player = Player.get(2)
    player.description.should == "\n"
    post "/players/2", params = { :description => "Test *markdown*" }
    follow_redirect!
    last_request.url.should == "http://example.org/players/2"
    last_response.should be_ok
    player = Player.get(2)
    player.description.should == "<p>Test <em>markdown</em></p>\n"
  end
  
  it "should not allow two players with the same e-mail" do
    p = Player.new(:email => "test1@test.com", :first_name => "value", :last_name => "value")
    p.valid?.should be false
  end
  
end