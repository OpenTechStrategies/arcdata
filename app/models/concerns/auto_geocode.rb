module AutoGeocode
  extend ActiveSupport::Concern

  mattr_accessor :enabled_in_test
  self.enabled_in_test = false

  included do
    before_save :geocode_address

    class_attribute :geocode_columns
    self.geocode_columns = %w(address1 address2 city state zip)
  end

  def geocode_address(force=false)
    cols = self.class.geocode_columns
    return if Rails.env.test? && !AutoGeocode.enabled_in_test
    return if self[cols.first] == 'Address' and city == 'City'
    
    if force or lat.nil? or lng.nil? or (changed & cols).present?
      address = cols.map{|c| self[c] }.compact.join " "
      res = Geokit::Geocoders::GoogleGeocoder3.geocode(address)
      if res
        (self.lat, self.lng) = res.lat, res.lng
      else
        self.lat = nil
        self.lng = nil
      end
    end

    return true
  rescue Geokit::TooManyQueriesError
    self.lat = nil
    self.lng = nil

    return true
  end

end