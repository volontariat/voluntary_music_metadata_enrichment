module Voluntary
  module Api
    module V1
      module Music
        class ReleasesController < Voluntary::Api::V1::BaseController
          respond_to :json
          
          def index
            respond_to do |format|
              format.json {
                render json: MusicRelease.where(artist_id: params[:artist_id]).order('released_at DESC').map(&:to_json).to_json
              }
            end
          end
          
          def bulk
            respond_to do |format|
              format.json { render json: MusicRelease.enrich_metadata(params[:releases]).to_json }
            end
          end
          
          def show
            respond_to do |format|
              format.json { render json: MusicRelease.find(params[:id]).to_json }
            end
          end
        end
      end
    end
  end
end