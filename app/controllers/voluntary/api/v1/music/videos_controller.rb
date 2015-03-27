module Voluntary
  module Api
    module V1
      module Music
        class VideosController < Voluntary::Api::V1::BaseController
          respond_to :json
          
          def index
            params[:page] = nil if params[:page] == ''
            params[:per_page] = nil if params[:per_page] == ''
            videos = MusicVideo.liked_by(params[:user_id]).order('likes.created_at DESC').paginate(per_page: params[:per_page] || 10, page: params[:page] || 1)
            
            respond_to do |format|
              format.json {
                render json: {
                  current_page: videos.current_page, per_page: videos.per_page, total_entries: videos.total_entries, total_pages: videos.total_pages,
                  entries: videos.map do |v| 
                    { 
                      id: v.id, status: v.status, artist_id: v.artist_id, artist_name: v.artist_name, 
                      track_id: v.track_id, track_name: v.track_name, url: v.url, liked_at: v.liked_at.iso8601
                    } 
                  end,
                }.to_json
              }
            end
          end
        end
      end
    end
  end
end