Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"

      resources :events do
        resources :ticket_tiers, only: [:index, :create, :update, :destroy]
        post "bookmark", to: "bookmarks#create"
        delete "bookmark", to: "bookmarks#destroy"
      end

      resources :orders, only: [:index, :show, :create] do
        member do
          post :cancel
        end
      end

      resources :bookmarks, only: [:index]
    end
  end
end
