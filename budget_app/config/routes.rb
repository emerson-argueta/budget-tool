Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions", registrations: "registrations" }

  get  "two_factor/setup",        to: "two_factor#setup",        as: :two_factor_setup
  post "two_factor/enable",       to: "two_factor#enable",       as: :two_factor_enable
  get  "two_factor/verify",       to: "two_factor#verify",       as: :two_factor_verify
  post "two_factor/authenticate", to: "two_factor#authenticate", as: :two_factor_authenticate

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
  resources :accounts, only: [:index, :show] do
    collection do
      delete :clear_cash
    end
  end
  resources :plaid_items, only: [:destroy]
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
