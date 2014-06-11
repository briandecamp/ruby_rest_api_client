if ARGV.length != 2
  raise "Expected use: ruby sample.rb username password"
end

# for this code to work, you will need to have the Faraday gem (https://github.com/lostisland/faraday)
# installed on your system:
#
# gem install faraday

    # Copyright 2000-2014 NeuStar, Inc. All rights reserved.
    # NeuStar, the Neustar logo and related names and logos are registered
    # trademarks, service marks or tradenames of NeuStar, Inc. All other
    # product names, company names, marks, logos and symbols may be trademarks
    # of their respective owners.


require_relative 'rest_client'

c = UltraRestApi::RestClient.new(ARGV[0], ARGV[1])
puts c.version
puts c.status
account_details = c.get_account_details
puts account_details
account_name = account_details['accounts'][0]['accountName']
puts account_name
puts c.create_primary_zone(account_name, 'foo.invalid.')
puts c.get_zone_metadata 'foo.invalid.'
puts c.delete_zone 'foo.invalid.'
all_zones = c.get_zones_of_account(account_name, q: {zone_type:'PRIMARY'}, offset: 0, limit: 5)
puts all_zones
first_zone_name = all_zones['zones'][0]['properties']['name']
puts first_zone_name
puts c.get_rrsets first_zone_name
puts c.create_rrset(first_zone_name, 'A', 'foo', 300, '1.2.3.4')
puts c.get_rrsets first_zone_name
puts c.get_rrsets_by_type(first_zone_name, 'A')
puts c.edit_rrset(first_zone_name, "A", "foo", 100, ["10.20.30.40"])
puts c.get_rrsets first_zone_name
puts c.get_rrsets_by_type(first_zone_name, 'A')
puts c.delete_rrset(first_zone_name, 'A', 'foo')
puts c.get_rrsets first_zone_name
puts c.get_rrsets_by_type(first_zone_name, 'A') #this will generated a 404 error since the resource records set was deleted
