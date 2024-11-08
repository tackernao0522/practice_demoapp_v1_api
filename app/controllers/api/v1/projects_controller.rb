class Api::V1::ProjectsController < ApplicationController
  before_action :authenticate_active_user

  def index
    projects = []
    date = Date.new(2021, 4, 1)
    10.times do |n|
      id = n + 1
      name = "#{current_user.name} project # {id.to_s.rjust(2, '0)}"
      updated_at = date + (id * 6).hours
      projects << { id: id, name: name, updatedAt: updated_at}
      # 本来はcurrent_user.projects
    end

    render json: projects
  end
end
