namespace :voluntary, path: 'api', module: 'voluntary/api', defaults: {format: 'json'} do
  namespace :v1 do
    namespace :music do
      resources :artists, only: [:index, :show] do
        resources :releases, only: [:index]
      end
      
      resources :releases, only: [:show] do
        collection do
          get :bulk
          post :bulk
        end
        
        resources :tracks, only: [:index]
      end  
      
      resources :tracks, only: [:show] do
        collection do
          get :bulk
          post :bulk
        end
      end  
    end
    
    resources :users, only: [:show] do
      namespace :library, path: 'library/music', module: 'music', as: :library_music do
        resources :year_in_reviews, only: [:index, :show] do
          member do
            get :top_releases
            get :top_tracks
          end
        end
        
        resources :videos, only: [:index]
      end
    end
  end
end