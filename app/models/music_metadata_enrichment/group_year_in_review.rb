module MusicMetadataEnrichment
  class GroupYearInReview < ActiveRecord::Base
    self.table_name = 'music_metadata_enrichment_group_year_in_review'
    
    belongs_to :group, class_name: 'MusicMetadataEnrichment::Group'
    
    has_many :releases, class_name: 'MusicMetadataEnrichment::GroupYearInReviewRelease', foreign_key: 'year_in_review_music_id', dependent: :delete_all
    has_many :tracks, class_name: 'MusicMetadataEnrichment::GroupYearInReviewTrack', foreign_key: 'year_in_review_music_id', dependent: :delete_all
    
    validates :group_id, presence: true
    validates :year, presence: true, numericality: { only_integer: true }, uniqueness: { scope: :group_id }
    
    attr_accessible :group_id, :year
    
    def self.update_for_groups
      MusicMetadataEnrichment::Group.find_each do |group|
        update_for_group(group)
      end
    end
    
    def self.update_for_group(group)
      group.year_in_reviews_of_members.published.group('year_in_review_music.year').map(&:year).sort.each do |year|
        group_year_in_review = group.year_in_reviews.where(year: year).first_or_create
        year_in_review_of_members = group.year_in_reviews_of_members.published.where('year_in_review_music.year = ?', year)
        group_year_in_review.update_attribute(:users_count, year_in_review_of_members.count)
        items = { releases: {}, tracks: {} }
        item_type_specific_attribute = { releases: :release_id, tracks: :track_id }
        
        year_in_review_of_members.each do |year_in_review|
          items.each do |item_type, items_by_id|
            user_items = year_in_review.send(item_type).order("year_in_review_music_#{item_type}.position ASC").to_a
            items_count = user_items.length
            
            user_items.each do |item|
              item_id = item.send(item_type_specific_attribute[item_type])
              items[item_type][item_id] ||= { users_count: 0, score: 0 }
              items[item_type][item_id][:users_count] += 1
              items[item_type][item_id][:score] += (items_count - item.position + 1)
            end
          end
        end
        
        ranking = { releases: {}, tracks: {}}
        
        items.each do |item_type, items_by_id|
          items_by_id.each do |item_id, hash|
            #score = (hash[:score].to_f / hash[:users_count]).round(2)
            score = (hash[:score].to_f / group_year_in_review.users_count).round(2)
            ranking[item_type][score] ||= []
            ranking[item_type][score] << item_id
          end
        end
        
        ranking.each do |item_type, items_by_score|
          position = 1
          
          items_by_score.keys.sort.reverse.each do |score|
            items_by_score[score].each do |item_id|
              group_year_in_review.send(item_type).create!(
                { year: year, position: position, score: score, group_id: group.id, item_type_specific_attribute[item_type] => item_id }
              )
            end
            
            position += items_by_score[score].length
            
            break if position >= 51
          end
        end
      end
    end
  end
end