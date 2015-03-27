module Voluntary
  module Api
    module V1
      module Music
        class VideosController < Voluntary::Api::V1::BaseController
          respond_to :json
          
          def index
            primitive_videos = if params[:track_id].present?
              MusicVideo.where(track_id: params[:track_id]).order_by_status.map(&:to_json)
            else
              params[:page] = nil if params[:page] == ''
              params[:per_page] = nil if params[:per_page] == ''
              videos = MusicVideo.liked_by(params[:user_id]).order('likes.created_at DESC').paginate(per_page: params[:per_page] || 10, page: params[:page] || 1)
            
              {
                current_page: videos.current_page, per_page: videos.per_page, total_entries: videos.total_entries, total_pages: videos.total_pages,
                entries: videos.map do |video| 
                  video.to_json.merge(liked_at: video.liked_at.iso8601)
                end,
              }
            end
             
            respond_to do |format|
              format.json { render json: primitive_videos.to_json }
            end
          end
          
          def show
            respond_to do |format|
              format.json { render json: MusicVideo.find(params[:id]).to_json }
            end
          end
        end
      end
    end
  end
end