require 'spec_helper'

describe MusicMetadataEnrichment::GroupYearInReview do
  describe '.update_for_group' do
    before :each do
      allow_any_instance_of(Lastfm).to receive(:request).and_return(
        Lastfm::Response.new(
          %Q{
            <lfm status="ok">
              <members for="Linux" page="1" perPage="50" totalPages="1" total="1">
                <user>
                  <name>RJ</name>
                  <realname>Richard Jones</realname>
                  <image size="small">http://test.com/1.jpg</image>
                  <image size="medium">http://test.com/2.jpg</image>
                  <image size="large">http://test.com/3.jpg</image>
                  <image size="extralarge">http://test.com/4.jpg</image>
                  <url>http://www.last.fm/user/RJ</url>
                </user>
              </members>
            </lfm>
          }
        )
      )
      
      @year = 2014
      @user = FactoryGirl.create(:user)
      @group = FactoryGirl.build(:music_metadata_enrichment_group)
      @group.user_id = @user.id
      @group.save!
      
      @year_in_review = @user.years_in_review_music.create!(year: @year)
      @year_in_review.publish!
      @mbids = [
        ("a" * 36), ("b" * 36), ("c" * 36), ("d" * 36), ("e" * 36), ("f" * 36), ("g" * 36), ("h" * 36), ("i" * 36), ("j" * 36),
        ("k" * 36), ("l" * 36), ("m" * 36), ("n" * 36), ("o" * 36), ("p" * 36), ("q" * 36), ("r" * 36), ("s" * 36), ("t" * 36),
        ("u" * 36), ("v" * 36), ("w" * 36), ("x" * 36), ("y" * 36), ("z" * 36), ("g" * 33) + '001', ("h" * 33) + '002', ("i" * 33) + '003', 
        ("j" * 33) + '004', ("a" * 33) + '005', ("b" * 33) + '006', ("c" * 33) + '007', ("d" * 33) + '008', ("e" * 33) + '009', 
        ("f" * 33) + '010', ("g" * 33) + '011', ("h" * 33) + '012', ("i" * 33) + '013', ("j" * 33) + '014',
        ("a" * 33) + '015', ("b" * 33) + '016', ("c" * 33) + '017', ("d" * 33) + '018', ("e" * 33) + '019', ("f" * 33) + '020', 
        ("g" * 33) + '021', ("h" * 33) + '022', ("i" * 33) + '023', ("j" * 33) + '024', ("a" * 33) + '025'
      ]
      @artist = FactoryGirl.create(:music_artist, mbid: @mbids.pop)
    end

    context 'less than 50 different positions per top list' do    
      it 'ranks items by average score descending' do
        releases = []; 3.times { releases << FactoryGirl.create(:music_release, artist: @artist, mbid: @mbids.pop) }
        
        releases.each do |release|
          @year_in_review.releases.create(year: @year, release_id: release.id, user_id: @user.id)
        end
        
        tracks = []; 3.times { tracks << FactoryGirl.create(:music_track, artist: @artist, release: releases.first, mbid: @mbids.pop) }
        
        tracks.each do |track|
          @year_in_review.tracks.create(year: @year, track_id: track.id, user_id: @user.id)
        end
        
        user = FactoryGirl.create(:user)
        @group.memberships.create!(user_id: user.id)
        year_in_review = user.years_in_review_music.create!(year: @year)
        year_in_review.publish!
        releases << FactoryGirl.create(:music_release, artist: @artist, mbid: @mbids.pop)
        
        [releases.second, releases.fourth, releases.third, releases.first].each do |release|
          year_in_review.releases.create(year: @year, release_id: release.id, user_id: user.id)
        end
        
        tracks << FactoryGirl.create(:music_track, artist: @artist, release: releases.first, mbid: @mbids.pop)
        
        [
          tracks.first, tracks.third, tracks.fourth, tracks.second
        ].each do |track|
          year_in_review.tracks.create(year: @year, track_id: track.id, user_id: user.id)
        end
        
        described_class.update_for_group(@group)
        
        group_year_in_review = @group.year_in_reviews.where(year: @year).first
        
        expect(group_year_in_review.users_count).to be == 2
        expect(
          [
            group_year_in_review.releases.order('music_metadata_enrichment_group_year_in_review_releases.position ASC').map{|r|
              { position: r.position, score: r.score, release_id: r.release_id }
            },
            group_year_in_review.tracks.order('music_metadata_enrichment_group_year_in_review_tracks.position ASC').map{|t|
              { position: t.position, score: t.score, track_id: t.track_id }
            }
          ]
        ).to be == [
          [
            { position: 1, score: 3.0, release_id: releases.second.id },
            { position: 2, score: 2.0, release_id: releases.first.id },
            { position: 3, score: 1.5, release_id: releases.third.id },
            { position: 3, score: 1.5, release_id: releases.fourth.id },
          ],
          [
            { position: 1, score: 3.5, track_id: tracks.first.id },
            { position: 2, score: 2.0, track_id: tracks.third.id },
            { position: 3, score: 1.5, track_id: tracks.second.id },
            { position: 4, score: 1.0, track_id: tracks.fourth.id },
          ]
        ]
      end
    end
    
    context 'more than 50 positions per top list' do
      it 'does not create items for releases or tracks with higher position than 50' do
        51.times do
          release = FactoryGirl.create(:music_release, artist: @artist, mbid: @mbids.pop)
          @year_in_review.releases.create(year: @year, release_id: release.id, user_id: @user.id)
        end
        
        described_class.update_for_group(@group)
          
        group_year_in_review = @group.year_in_reviews.where(year: @year).first
        
        expect(group_year_in_review.releases.count).to be == 50
        expect(
          group_year_in_review.releases.order('music_metadata_enrichment_group_year_in_review_releases.position ASC').last.position
        ).to be == 50
      end
    end
  end
end