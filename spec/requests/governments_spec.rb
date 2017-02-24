require 'rails_helper'

RSpec.describe "Governments", type: :request do
  describe "GET /governments" do
    it "works! (now write some real specs)" do
      get governments_path
      expect(response).to have_http_status(200)
    end
  end
end
