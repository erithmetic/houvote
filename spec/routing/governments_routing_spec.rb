require "rails_helper"

RSpec.describe GovernmentsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/governments").to route_to("governments#index")
    end

    it "routes to #new" do
      expect(:get => "/governments/new").to route_to("governments#new")
    end

    it "routes to #show" do
      expect(:get => "/governments/1").to route_to("governments#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/governments/1/edit").to route_to("governments#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/governments").to route_to("governments#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/governments/1").to route_to("governments#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/governments/1").to route_to("governments#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/governments/1").to route_to("governments#destroy", :id => "1")
    end

  end
end
