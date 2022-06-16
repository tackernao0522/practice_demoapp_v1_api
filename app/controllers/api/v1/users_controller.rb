class Api::V1::UsersController < ApplicationController
  before_action :authenticate_active_user

  def index
    # users = User.all
    # as_json => ハッシュの形でSONデータを返す { "id" => 1, "name" => "test", ... }
    render json: current_user.as_json(only: [:id, :name, :email, :created_at])
  end
end
