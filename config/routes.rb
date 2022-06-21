Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # api test action
      resources :auth_token, only: %i[create] do
        post :refresh, on: :collection
        delete :destroy, on: :collection
      end

      # projects
      resources :projects, only: %i[index]
    end
  end
end
