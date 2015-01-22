Rails.application.routes.draw do
  get '/products/music-metadata-enrichment' => 'product/music_metadata_enrichment#index', as: 'music_metadata_enrichment_product'
  #get '/music_metadata_enrichment' => 'product/music_metadata_enrichment#index'
  get '/music' => 'product/music_metadata_enrichment#index'
  get '/music_metadata_enrichment', to: redirect('/music')
  get '/music-metadata-enrichment', to: redirect('/music')
  
  namespace :music, module: 'music_metadata_enrichment' do
    resources :groups, only: [:index, :new, :create, :show] do
      resources :artists, only: [:index, :new], controller: 'group_artist_connections' do
        collection do
          get :import
          get :name_confirmation
          get :select_artist
          get :creation
        end
      end
      
      member do
        get 'releases' => 'group_release_connections#index'
      end
      
      resources :releases, only: [:new]
      resources :videos, only: [:index, :new]
    end
      
    resources :artists, only: [:index, :new, :create, :show] do
      collection do
        get :name_confirmation
        get 'by_name/:name', to: 'artists#by_name'
      end
      
      resources :releases, only: [:new]
      resources :videos, only: [:index, :new]
    end
    
    resources :releases, only: [:index, :new, :create, :show] do
      collection do
        get :artist_confirmation
        get :select_artist
        get :name
        get :name_confirmation
        get :announce
        post :create_announcement
        get 'by_name/:artist_name/:name', to: 'releases#by_name'
      end
    end
    
    resources :tracks, only: [:index, :new, :create, :show] do
      collection do
        get :artist_confirmation
        get :select_artist
        get :name
        get :name_confirmation
        get 'by_name/:artist_name/:name', to: 'tracks#by_name'
      end
      
      resources :videos, only: [:new]
    end
    
    resources :videos, only: [:index, :new, :create, :show] do
      collection do
        get :artist_confirmation
        get :select_artist
        get :track_name
        get :track_confirmation
        get :create_track
        get :metadata
        get 'by_name/:artist_name/:name', to: 'videos#by_name'
      end
    end
  end
end