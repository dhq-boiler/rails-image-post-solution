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
  end
end
