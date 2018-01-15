class TrelloWebhooksController < ApplicationController
  unloadable

  def index
    respond_to do |format|
      format.html
      format.json { render json: {} }
    end
  end

  def create
    respond_to do |format|
      format.html
      format.json { render json: {} }
    end
  end
end
