# frozen_string_literal: true

RailsImagePostSolution::Engine.routes.draw do
  # ユーザー向け通報API
  resources :image_reports, only: [:create]

  # 管理者向けダッシュボード
  namespace :admin do
    resources :image_reports, only: [:index, :show] do
      member do
        patch :confirm
        patch :dismiss
      end
    end
  end
end
