namespace :voluntary, path: 'api', module: 'voluntary/api', defaults: {format: 'json'} do
  namespace :v1 do
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