module Voluntary
  module Api
    module V1
      module Music
        class TracksController < Voluntary::Api::V1::BaseController
          respond_to :json
          
          def index
            respond_to do |format|
              format.json {
                render json: MusicTrack.where(release_id: params[:release_id]).order('nr ASC').map(&:to_json).to_json
              }
            end
          end
          
          def bulk
            respond_to do |format|
              format.json { render json: MusicTrack.enrich_metadata(params[:tracks]).to_json }
            end
          end
          
          def show
            respond_to do |format|
              format.json { render json: MusicTrack.find(params[:id]).to_json }
            end
          end
        end
      end
    end
  end
end