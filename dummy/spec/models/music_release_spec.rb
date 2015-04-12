require 'spec_helper'

describe MusicRelease do
  describe 'validations' do
    describe '#future_release_date_format' do
      context 'blank' do
        it 'is valid' do
          release = FactoryGirl.build(:music_release)
          
          release.valid?
          
          release.errors[:future_release_date].empty?.should be_truthy
          release.future_release_date.should be_nil
          release.released_at.should be_nil
        end
      end
      
      context 'XX.01.2015' do
        it 'is valid' do
          release = FactoryGirl.build(:music_release, future_release_date: 'XX.01.2015')
          
          release.valid?
          
          release.errors[:future_release_date].empty?.should be_truthy
          release.released_at.strftime('%d.%m.%Y').should == '31.01.2015'
        end
      end
      
      context 'XX.XX.2015' do
        it 'is valid' do
          release = FactoryGirl.build(:music_release, future_release_date: 'XX.XX.2015')
          
          release.valid?
          
          release.errors[:future_release_date].empty?.should be_truthy
          release.released_at.should == Time.local(2015, 12, 31)
        end
      end
      
      context '01.01.2015' do
        it 'is valid' do
          release = FactoryGirl.build(:music_release, future_release_date: '01.01.2015')
          
          release.valid?
          
          release.errors[:future_release_date].empty?.should be_truthy
          release.released_at.should == Time.local(2015, 1, 1)
        end
      end   
      
      context 'North Spring 2015' do
        it 'is valid' do
          release = FactoryGirl.build(:music_release, future_release_date: 'North Spring 2015')
          
          release.valid?
          
          release.errors[:future_release_date].empty?.should be_truthy
          release.released_at.should == Time.local(2015, 6, 22)
        end
      end
      
      context 'Dummy' do
        it 'is invalid' do
          release = FactoryGirl.build(:music_release, future_release_date: 'Dummy')
          
          release.valid?
          
          release.errors[:future_release_date].should include(I18n.t('activerecord.errors.models.music_release.attributes.future_release_date.wrong_format'))
          release.released_at.should be_nil
        end
      end                   
    end
  end
end
