Rails.application.routes.draw do

  root 'dashboard#index'
  
  #devise_for :users
 
  resources :ad_hoc_reports, only: [:index, :show, :new, :create, :destroy] do
    member do
      get :run_start
      get :run_progress
      get :run_results
      get :results
      get :export_csv
    end
  end
  
  resources :cdisc_terms do
    collection do
      # get :find_submission
      get :changes
    end
  end

  resources :forms do
    collection do
      get :history
    end
  end

  resources :biomedical_concepts do
    member do
      get :export_json
      get :export_ttl
      get :clone
      get :upgrade
      get :show_full
      get :edit_lock
    end
    collection do
      get :editable
      get :history
      post :clone_create
      get :list
      get :edit_multiple
    end
  end
  
  #namespace :sdtm_user_domains do
  #  resources :variables
  #end
end
