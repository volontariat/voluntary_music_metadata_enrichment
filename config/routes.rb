Rails.application.routes.draw do
  get '/products/music-metadata-enrichment', to: redirect('/music'), as: 'music_metadata_enrichment_product'
  #get '/music_metadata_enrichment' => 'product/music_metadata_enrichment#index'
  get '/music' => 'product/music_metadata_enrichment#index'
  get '/music_metadata_enrichment', to: redirect('/music')
  get '/music-metadata-enrichment', to: redirect('/music')
  
  namespace :music, module: 'music_metadata_enrichment' do
    resources :groups, only: [:index, :new, :create, :show] do
      resources :memberships, only: [:create], controller: 'group_memberships'
      
      resources :artists, only: [:new], controller: 'group_artist_connections' do
        collection do
          get :import
          post :import, as: :post_import
          get :name_confirmation
          get :select_artist
          get :creation
        end
      end
      
      member do
        get 'artists' => 'artists#index'
        get 'releases' => 'releases#index'
        get 'releases/export' => 'releases#export'
      end
      
      resources :releases, only: [:new]
      resources :videos, only: [:index, :new]
    end
    
    resources :group_memberships, only: [:destroy]
      
    resources :artists, only: [:index, :new, :create, :show] do
      collection do
        get :name_confirmation
        get 'by_name/:name', to: 'artists#by_name'
        get :by_name, as: :by_name
        get :autocomplete
      end
      
      resources :releases, only: [:new] do
        collection do
          get :autocomplete
        end
      end
      
      resources :tracks, only: [] do
        collection do
          get :autocomplete
        end
      end
      
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
        get :by_name, as: :by_name
      end
    end
    
    resources :tracks, only: [:index, :new, :create, :show] do
      collection do
        get :artist_confirmation
        get :select_artist
        get :name
        get :name_confirmation
        get 'by_name/:artist_name/:name', to: 'tracks#by_name'
        get :by_name, as: :by_name
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
        get :by_name, as: :by_name
      end
    end
  end
  
  get 'users/:user_id/library/music' => 'library/music#index', as: :user_music_library
  
  get 'users/:user_id/library/music/years_in_review' => 'library/music/years_in_review#index', as: :user_music_years_in_review
  post 'users/:user_id/library/music/years_in_review' => 'library/music/years_in_review#create', as: :create_user_music_year_in_review
  get 'users/:user_id/library/music/years_in_review/:year' => 'library/music/years_in_review#show', as: :user_music_year_in_review
  
  get 'users/:user_id/library/music/years_in_review/:year/top_releases' => 'library/music/year_in_review_releases#index', as: :user_music_year_in_review_top_releases
  get 'users/:user_id/library/music/years_in_review/:year/top_releases/new' => 'library/music/year_in_review_releases#new', as: :new_user_music_year_in_review_top_release
  post 'users/:user_id/library/music/years_in_review/:year/top_releases' => 'library/music/year_in_review_releases#create', as: :create_user_music_year_in_review_top_release
  post 'users/:user_id/library/music/years_in_review/:year/flop_releases' => 'library/music/year_in_review_release_flops#create', as: :create_user_music_year_in_review_flop_release
  get 'users/current/library/music/years_in_review/:year/top_releases/multiple_new' => 'library/music/year_in_review_releases#multiple_new', as: :multiple_new_user_music_year_in_review_top_releases
  post 'users/:user_id/library/music/years_in_review/:year/top_releases/create_multiple' => 'library/music/year_in_review_releases#create_multiple', as: :create_multiple_user_music_year_in_review_top_releases
  delete 'users/current/library/music/year_in_review_music_releases/:id' => 'library/music/year_in_review_releases#destroy', as: :destroy_music_year_in_review_top_release
  put 'users/current/library/music/year_in_review_music_releases/:id/move' => 'library/music/year_in_review_releases#move', as: :move_music_year_in_review_top_release
  get 'users/current/library/music/years_in_review/:year/top_releases/export' => 'library/music/year_in_review_releases#export', as: :export_music_year_in_review_top_releases
  
  get 'users/:user_id/library/music/years_in_review/:year/top_tracks' => 'library/music/year_in_review_tracks#index', as: :user_music_year_in_review_top_tracks
  get 'users/:user_id/library/music/years_in_review/:year/top_tracks/new' => 'library/music/year_in_review_tracks#new', as: :new_user_music_year_in_review_top_track
  post 'users/:user_id/library/music/years_in_review/:year/top_tracks' => 'library/music/year_in_review_tracks#create', as: :create_user_music_year_in_review_top_track
  post 'users/:user_id/library/music/years_in_review/:year/flop_tracks' => 'library/music/year_in_review_track_flops#create', as: :create_user_music_year_in_review_flop_track
  get 'users/current/library/music/years_in_review/:year/top_tracks/multiple_new' => 'library/music/year_in_review_tracks#multiple_new', as: :multiple_new_user_music_year_in_review_top_tracks
  post 'users/:user_id/library/music/years_in_review/:year/top_tracks/create_multiple' => 'library/music/year_in_review_tracks#create_multiple', as: :create_multiple_user_music_year_in_review_top_tracks
  delete 'users/current/library/music/year_in_review_music_tracks/:id' => 'library/music/year_in_review_tracks#destroy', as: :destroy_music_year_in_review_top_track
  put 'users/current/library/music/year_in_review_music_tracks/:id/move' => 'library/music/year_in_review_tracks#move', as: :move_music_year_in_review_top_track
  get 'users/current/library/music/years_in_review/:year/top_tracks/export' => 'library/music/year_in_review_tracks#export', as: :export_music_year_in_review_top_tracks
  
  get 'users/:user_id/library/music/releases' => 'music_metadata_enrichment/releases#index', as: :user_music_library_releases
  get 'users/:user_id/library/music/videos' => 'music_metadata_enrichment/videos#index', as: :user_music_library_videos
  get 'users/:user_id/library/music/artists' => 'music_metadata_enrichment/artists#index', as: :user_music_library_artists
  get 'users/:user_id/library/music/artists/new' => 'music_metadata_enrichment/artists#new', as: :new_user_music_library_artist
  delete 'users/current/library/music/artists/:id' => 'library/music/artists#destroy', as: :destroy_music_library_artist
end