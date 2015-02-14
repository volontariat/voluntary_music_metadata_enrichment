module Library
  module Music
    module YearInReviewsHelper
      def group_or_user_path(path, param = nil)
        prefix = @group.present? ? 'group' : 'user'
        full_path = "#{prefix}_#{path}_path"
        
        case path
        when 'music_years_in_review'
          send(full_path, @group || @user)
        when 'export_music_year_in_review_top_tracks', 'export_music_year_in_review_top_releases'
          full_path = full_path.gsub("#{prefix}_", '') if @group.blank?
          
          @group.blank? ? send(full_path, param) : send(full_path, @group, param)
        else
          id = @group.present? ? param.group_id : param.user_id
          send(full_path, id, param.year)
        end
      end
    end
  end
end