module Voluntary
  module Api
    module V1
      module Music
        class ArtistsController < Voluntary::Api::V1::BaseController
          respond_to :json
          
          def index
            params[:page] = nil if params[:page] == ''
            params[:per_page] = nil if params[:per_page] == ''
            artists = MusicArtist
            artists = artists.where(state: params[:state]) if params[:state].present?
            artists = artists.order('name ASC').paginate(per_page: params[:per_page] || 10, page: params[:page] || 1)
            
            respond_to do |format|
              format.json {
                render json: {
                  current_page: artists.current_page, per_page: artists.per_page, total_entries: artists.total_entries, total_pages: artists.total_pages,
                  entries: artists.map(&:to_json),
                }.to_json
              }
            end
          end
          
          def show
            respond_to do |format|
              format.json { render json: MusicArtist.find(params[:id]).to_json }
            end
          end
        end
      end
    end
  end
end