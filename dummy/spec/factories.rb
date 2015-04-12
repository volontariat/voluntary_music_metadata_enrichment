def r_str
  SecureRandom.hex(3)
end

def resource_has_many(resource, association_name)
  association = if resource.send(association_name).length > 0
    nil
  elsif association_name.to_s.classify.constantize.count > 0
    association_name.to_s.classify.constantize.last
  else
    Factory.create association_name.to_s.singularize.to_sym
  end
  
  resource.send(association_name).send('<<', association) if association
end

FactoryGirl.define do
  Voluntary::Test::RspecHelpers::Factories.code.call(self)
  
  factory :music_artist do
    sequence(:mbid) { |n| Faker::Lorem.characters(36) } 
    sequence(:name) { |n| "music artist #{n}#{r_str}" } 
  end
  
  factory :music_release do
    sequence(:mbid) { |n| Faker::Lorem.characters(36) } 
    association :artist, factory: :music_artist
    sequence(:name) { |n| "music release #{n}#{r_str}" } 
  end
  
  factory :music_track do
    sequence(:mbid) { |n| Faker::Lorem.characters(36) } 
    association :artist, factory: :music_artist
    association :release, factory: :music_release
    sequence(:name) { |n| "music release #{n}#{r_str}" } 
  end
  
  factory :music_metadata_enrichment_group, class: MusicMetadataEnrichment::Group do
    sequence(:name) { |n| "group #{n}#{r_str}" }
  end
  
  factory :year_in_review_music do
    association :user
    sequence(:year) {|n| n }
  end
end