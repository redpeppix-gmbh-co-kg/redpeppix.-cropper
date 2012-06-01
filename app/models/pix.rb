# == Pix
#
# Schnittstelle zu redpeppix., Adresse: https://www.redpeppix.de/api/pixes.
# Format: XML. Die Schnittstelle liefert Informationen über Pix. 
#
# === Aufbau des XML
# Aufruf z.B.: https://www.redpeppix.de/api/pixes/31545.xml
#
# siehe http://wiki.redpeppix.de
#
class Pix < ActiveResource::Base
  if Rails.env.production?
    self.site = "https://www.pixoona.com"
  elsif Rails.env.staging?
    self.site = "https://www.com-pix.com"
  else
    self.site = "http://barbra-streisand.dev"
  end
  self.format = :json
  self.prefix = "/api/"
end