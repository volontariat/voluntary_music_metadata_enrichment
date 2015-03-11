module Voluntary
  module Api
    module V1
      module Music
        class YearInReviewsController < Voluntary::Api::V1::BaseController
          before_filter :find_user
          
          respond_to :json
          
          def index
            years_in_review = @user.years_in_review_music.published
            params[:page] = nil if params[:page] == ''
            params[:per_page] = nil if params[:per_page] == ''
            years_in_review = years_in_review.order('year DESC').paginate(per_page: params[:per_page] || 10, page: params[:page] || 1)

            respond_to do |f|
              f.json {
                render json: {
                  current_page: years_in_review.current_page, per_page: years_in_review.per_page, total_entries: years_in_review.total_entries,
                  total_pages: years_in_review.total_pages,
                  entries: years_in_review.map{|r| { year: r.year } },
                }.to_json
              }
            end
          end
          
          def show
            respond_to {|f| f.json { render json: { year: year_in_review.year }.to_json } }
          end
          
          def top_releases
            releases = year_in_review.releases.order('position ASC')
            tracks = year_in_review.tracks.order('position ASC').group_by(&:release_id)
            tracks_count = tracks.values.flatten.length
            
            respond_to do |f|
              f.json {
                render json: releases.map {|year_in_review_release|
                  {
                    position: year_in_review_release.position,
                    artist_name: year_in_review_release.artist_name,
                    artist_id: year_in_review_release.artist_id,
                    release_id: year_in_review_release.release_id,
                    release_name: year_in_review_release.release_name,
                    top_track_positions_sum: (
                      (tracks[year_in_review_release.release_id] || []).sum{|t| tracks_count - t.position + 1 }
                    ),
                    top_tracks: (tracks[year_in_review_release.release_id] || []).map do |t| 
                      { position: t.position, track_name: t.track_name, track_id: t.track_id }
                    end
                  }
                }.to_json
              }
            end
          end  
          
          def top_tracks
            tracks = year_in_review.tracks.order('position ASC')
            
            respond_to do |f|
              f.json {
                render json: tracks.map {|year_in_review_track|
                  {
                    position: year_in_review_track.position,
                    artist_name: year_in_review_track.artist_name,
                    artist_id: year_in_review_track.artist_id,
                    release_id: year_in_review_track.release_id,
                    release_name: year_in_review_track.release_name,
                    track_id: year_in_review_track.track_id,
                    track_name: year_in_review_track.track_name
                  }
                }.to_json
              }
            end
          end  
          
          private
          
          def find_user
            @user = User.find(params[:user_id])
          end
          
          def year_in_review
            @year_in_review ||= @user.years_in_review_music.published.where(year: params[:id]).first
            
            raise ActiveRecord::RecordNotFound if @year_in_review.nil?
            
            @year_in_review
          end
        end
      end
    end
  end
end