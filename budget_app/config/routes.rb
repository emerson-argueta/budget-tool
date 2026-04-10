Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }

  authenticated :user do
    root "dashboard#show", as: :authenticated_root
  end

  devise_scope :user do
    root "devise/sessions#new", as: :unauthenticated_root
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Plaid Link loads internal resources from the host domain under /_/
  get "/_/*path", to: proc { [204, {}, []] }

  resource :dashboard, only: [:show], controller: "dashboard"
  resources :budgets, param: :month do
    member do
      post :copy_previous
    end
    resources :budget_categories, shallow: true do
      member do
        patch :update_amount
      end
    end
  end
  resources :transactions, only: [:index, :show, :new, :create, :update] do
    collection do
      get :unassigned
      patch :bulk_assign
    end
  end
  resources :accounts, only: [:index, :show]
  resources :sinking_funds do
    member do
      patch :deposit
      patch :withdraw
    end
  end
  resources :reports, only: [:index]
  resources :category_groups, only: [:new, :create, :edit, :update, :destroy]

  namespace :plaid do
    get  :link                # renders page with link token + auto-opens Plaid Link
    post :exchange_token
    post :webhook
    post :sync
  end
end
