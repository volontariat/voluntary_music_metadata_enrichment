module Voluntary
  module Api
    module V1
      module Music
        class TracksController < Voluntary::Api::V1::BaseController
          respond_to :json
          
          def bulk
            respond_to do |format|
              format.json { render json: MusicTrack.enrich_metadata(params[:tracks]).to_json }
            end
          end
        end
      end
    end
  end
end