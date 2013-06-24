class Incidents::IncidentCreated
  def initialize(incident)
    @incident = incident
  end

  def save
    if @incident.save
      fire_notifications
    end
  end

  def fire_notifications
    county = @incident.county_id

    subscriptions = Incidents::NotificationSubscription.for_county(county).for_type('new_incident')
    subscriptions.each do |sub|
      Incidents::IncidentsMailer.new_incident(@incident, sub.person).deliver
    end
  end
end