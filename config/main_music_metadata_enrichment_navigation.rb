SimpleNavigation::Configuration.run do |navigation|
  instance_exec navigation, &VoluntaryMusicMetadataEnrichment::Navigation.code
end