# frozen_string_literal: true

RailsImagePostSolution::Engine.routes.draw do
  # Support optional locale parameter to match host application's routing
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    # User-facing report API
    resources :image_reports, only: [ :create ]

    # Admin dashboard (engine controllers)
    namespace :admin do
      # Image reports management
      resources :image_reports, only: %i[index show] do
        member do
          patch :confirm
          patch :dismiss
        end
      end

      # User management
      resources :users, only: %i[index show] do
        member do
          post :suspend
          post :unsuspend
          post :ban
          post :unban
        end
      end

      # Frozen posts management
      resources :frozen_posts, only: [ :index ] do
        collection do
          post "unfreeze_stage/:id", to: "frozen_posts#unfreeze_stage", as: :unfreeze_stage
          post "unfreeze_comment/:id", to: "frozen_posts#unfreeze_comment", as: :unfreeze_comment
          post "permanent_freeze_stage/:id", to: "frozen_posts#permanent_freeze_stage", as: :permanent_freeze_stage
          post "permanent_freeze_comment/:id", to: "frozen_posts#permanent_freeze_comment", as: :permanent_freeze_comment
          delete "destroy_stage/:id", to: "frozen_posts#destroy_stage", as: :destroy_stage
          delete "destroy_comment/:id", to: "frozen_posts#destroy_comment", as: :destroy_comment
        end
      end
    end
  end
end
