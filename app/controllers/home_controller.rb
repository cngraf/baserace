class HomeController < ApplicationController
  def index
  end

  def predict
    render match_id: :match_id
  end
end
