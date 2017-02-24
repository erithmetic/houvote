class PagesController < ApplicationController
  def home
    if params[:location]
      @results = LookupPeopleByAddress.call params[:location]
    end
  end
end
