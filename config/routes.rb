# frozen_string_literal: true

RailsImagePostSolution::Engine.routes.draw do
  # User-facing report API
  resources :image_reports, only: [ :create ]

  # Admin dashboard
  namespace :admin do
    resources :image_reports, only: %i[index show] do
      member do
        patch :confirm
        patch :dismiss
      end
    end

    # User management
    resources :users, only: [ :index, :show ] do
      member do
        patch :suspend
        patch :unsuspend
        patch :ban
        patch :unban
      end
    end

    # Frozen posts management
    resources :frozen_posts, only: [ :index ] do
      collection do
        patch "unfreeze_stage/:id", to: "frozen_posts#unfreeze_stage", as: :unfreeze_stage
        patch "unfreeze_comment/:id", to: "frozen_posts#unfreeze_comment", as: :unfreeze_comment
        patch "permanent_freeze_stage/:id", to: "frozen_posts#permanent_freeze_stage", as: :permanent_freeze_stage
        patch "permanent_freeze_comment/:id", to: "frozen_posts#permanent_freeze_comment", as: :permanent_freeze_comment
        delete "destroy_stage/:id", to: "frozen_posts#destroy_stage", as: :destroy_stage
        delete "destroy_comment/:id", to: "frozen_posts#destroy_comment", as: :destroy_comment
      end
    end
  end
end
