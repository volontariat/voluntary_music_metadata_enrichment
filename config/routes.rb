Rails.application.routes.draw do
  get '/products/music-metadata-enrichment' => 'product/music_metadata_enrichment#index', as: 'music_metadata_enrichment_product'
  get '/music_metadata_enrichment' => 'product/music_metadata_enrichment#index'
  
  namespace :music_metadata_enrichment do
    resources :artists, only: [:index, :new, :create, :show] do
      collection do
        get :name_confirmation
        get 'by_name/:name', to: 'artists#by_name'
      end
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
    end
  end
end