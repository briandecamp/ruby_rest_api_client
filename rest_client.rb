module UltraRestApi

  require_relative 'rest_client_connection'

  class RestClient
    
    # Copyright 2000-2014 NeuStar, Inc. All rights reserved.
    # NeuStar, the Neustar logo and related names and logos are registered
    # trademarks, service marks or tradenames of NeuStar, Inc. All other
    # product names, company names, marks, logos and symbols may be trademarks
    # of their respective owners.


    # Initialize an Ultra REST API client
    #
    # === Required Parameters
    #
    # * +username+ - The user name
    # * +password+ - The user's password
    #
    # === Optional Parameters
    #
    # * +:use_http+ - Use http instead of https.  Defaults to false, set to true only in test environments.  Will not work in production.
    # * +:host+ - host and port of the remote server.  Defaults to restapi.ultradns.com.
    #
    # === Examples
    #
    #     c = RestClient.new("myUname", "myPwd")
    #     c = RestClient.new("myUname", "myPwd", host: 'restapi-useast1b01-01.ct.ultradns.net:8080')
    def initialize(username, password, options = {})
      puts options
      use_http = options[:use_http] || false
      puts use_http
      host = options[:host] || 'restapi.ultradns.com'
      puts host
      @rest_api_connection = RestClientConnection.new(use_http, host)
      @rest_api_connection.auth(username, password)
    end

    # Create a primary zone
    #
    # === Required Parameters
    #
    # * +account_name+ - The account that the zone will be created under.  The user must have write access for zones in that account.
    # * +zone_name+ - The name of the zone.  The trailing . is optional.  The zone name must not be in use by anyone.
    #
    # === Examples
    #
    #     c.create_primary_zone('my_account', 'zone.invalid.')
    def create_primary_zone(account_name, zone_name)
      zone_properties = {:name => zone_name, :accountName => account_name, :type => 'PRIMARY'}
      primary_zone_info = {:forceImport => true, :createType => 'NEW'}

      zone_data = {:properties => zone_properties, :primaryCreateInfo => primary_zone_info}
      @rest_api_connection.post('/v1/zones', zone_data)
    end

    # List zones for account
    #
    # === Required Parameters
    #
    # * +account_name+ - One of the user's accounts.  The user must have read access for zone in that account.
    #
    # === Optional Parameters
    #
    # * +:q+ - The search parameters, in a hash.  Valid keys are:
    #          name - substring match of the zone name
    #          zone_type - one of :
    #              PRIMARY
    #              SECONDARY
    #              ALIAS
    # * +:sort+ - The sort column used to order the list. Valid values for the sort field are:
    #             NAME
    #             ACCOUNT_NAME
    #             RECORD_COUNT
    #             ZONE_TYPE
    # * +:reverse+ - Whether the list is ascending(false) or descending(true).  Defaults to true
    # * +:offset+ - The position in the list for the first returned element(0 based)
    # * +:limit+ - The maximum number of zones to be returned.
    #
    # === Examples
    #
    #     c.get_zones_of_account 'my_account'
    #     c.get_zones_of_account('my_account', q: {name: 'foo', zone_type: 'PRIMARY'}, sort: 'NAME', reverse: true, offset:10, limit:50)
    def get_zones_of_account(account_name, options={})
      @rest_api_connection.get("/v1/accounts/#{account_name}/zones", build_params(options))
    end

    # Get zone metadata
    #
    # === Required Parameters
    #
    # * +zone_name+ - The name of the zone.  The user must have read access to the zone.
    #
    # === Examples
    #
    #     c.get_zone_metadata 'foo.invalid.'
    def get_zone_metadata(zone_name)
      @rest_api_connection.get "/v1/zones/#{zone_name}"
    end

    # Delete a zone
    #
    # === Required Parameters
    #
    # * +zone_name+ - The name of the zone.
    #
    # === Examples
    #
    #     c.delete_zone 'foo.invalid.'
    def delete_zone(zone_name)
      @rest_api_connection.delete "/v1/zones/#{zone_name}"
    end

    # Returns the list of RRSets in the specified zone.
    #
    # === Required Parameters
    #
    # * +zone_name+ - The name of the zone.  The user must have read access to the zone.
    #
    # === Optional Parameters
    #
    # * +:q+ - The search parameters, in a hash.  Valid keys are:
    #          ttl - must match the TTL for the rrset
    #          owner - substring match of the owner name
    #          value - substring match of the first BIND field value
    # * +:sort+ - The sort column used to order the list. Valid values for the sort field are:
    #             OWNER
    #             TTL
    #             TYPE
    # * +:reverse+ - Whether the list is ascending(false) or descending(true).  Defaults to true
    # * +:offset+ - The position in the list for the first returned element(0 based)
    # * +:limit+ - The maximum number of zones to be returned.
    #
    # === Examples
    #
    #     c.get_rrsets 'foo.invalid.'
    def get_rrsets(zone_name, options={})
      @rest_api_connection.get("/v1/zones/#{zone_name}/rrsets", build_params(options))
    end

    # Returns the list of RRSets in the specified zone of the specified type.
    #
    # === Required Parameters
    #
    # * +zone_name+ - The name of the zone.
    # * +rtype+ - The type of the RRSets.  This can be numeric (1) or
    #             if a well-known name is defined for the type (A), you can use it instead.
    #
    # === Optional Parameters
    #
    # * +:q+ - The search parameters, in a hash.  Valid keys are:
    #          ttl - must match the TTL for the rrset
    #          owner - substring match of the owner name
    #          value - substring match of the first BIND field value
    # * +:sort+ - The sort column used to order the list. Valid values for the sort field are:
    #             OWNER
    #             TTL
    #             TYPE
    # * +:reverse+ - Whether the list is ascending(false) or descending(true).  Defaults to true
    # * +:offset+ - The position in the list for the first returned element(0 based)
    # * +:limit+ - The maximum number of zones to be returned.
    #
    # === Examples
    #
    #     c.get_rrsets_by_type('foo.invalid.', 'A')
    #     c.get_rrsets_by_type('foo.invalid.', 'TXT', q: {value: 'cheese', ttl:300}, offset:5, limit:10)
    def get_rrsets_by_type(zone_name, rtype, options={})
      @rest_api_connection.get("/v1/zones/#{zone_name}/rrsets/#{rtype}", build_params(options))
    end

    # Creates a new RRSet in the specified zone.
    #
    # === Required Parameters
    #
    # * +zone_name+ - The zone that contains the RRSet.The trailing dot is optional.
    # * +rtype+ - The type of the RRSet.This can be numeric (1) or
    #             if a well-known name is defined for the type (A), you can use it instead.
    # * +owner_name+ - The owner name for the RRSet.
    #                  If no trailing dot is supplied, the owner_name is assumed to be relative (foo).
    #                  If a trailing dot is supplied, the owner name is assumed to be absolute (foo.zonename.com.)
    # * +ttl+ - The updated TTL value for the RRSet.
    # * +rdata+ - The updated BIND data for the RRSet as a string.
    #             If there is a single resource record in the RRSet, you can pass in the single string or an array with a single element.
    #             If there are multiple resource records in this RRSet, pass in a list of strings.
    #
    # === Examples
    #
    #     c.create_rrset('zone.invalid.', 'A', 'foo', 300, '1.2.3.4')
    def create_rrset(zone_name, rtype, owner_name, ttl, rdata)
      rdata = [rdata] unless rdata.kind_of? Array

      rrset = {:ttl => ttl, :rdata => rdata}
      @rest_api_connection.post("/v1/zones/#{zone_name}/rrsets/#{rtype}/#{owner_name}", rrset)
    end

    def create_rrset_profile(zone_name, rtype, owner_name, ttl, rdata, profile={})
      rdata = [rdata] unless rdata.kind_of? Array
  
      rrset = {:ttl => ttl, :rdata => rdata, :profile => profile}
      @rest_api_connection.post("/v1/zones/#{zone_name}/rrsets/#{rtype}/#{owner_name}", rrset)
    end
    # Updates an existing RRSet in the specified zone.
    #
    # === Required Parameters
    #
    # * +zone_name+ - The zone that contains the RRSet.The trailing dot is optional.
    # * +rtype+ - The type of the RRSet.This can be numeric (1) or
    #             if a well-known name is defined for the type (A), you can use it instead.
    # * +owner_name+ - The owner name for the RRSet.
    #                  If no trailing dot is supplied, the owner_name is assumed to be relative (foo).
    #                  If a trailing dot is supplied, the owner name is assumed to be absolute (foo.zonename.com.)
    # * +ttl+ - The updated TTL value for the RRSet.
    # * +rdata+ - The updated BIND data for the RRSet as a string.
    #             If there is a single resource record in the RRSet, you can pass in the single string or an array with a single element.
    #             If there are multiple resource records in this RRSet, pass in a list of strings.
    #                                                                                                                                                                                                                #
    # === Examples
    #
    #     c.edit_rrset('zone.invalid.', "A", "foo", 100, ["10.20.30.40"])
    def edit_rrset(zone_name, rtype, owner_name, ttl, rdata)
      rdata = [rdata] unless rdata.kind_of? Array

      rrset = {:ttl => ttl, :rdata => rdata}
      @rest_api_connection.put("/v1/zones/#{zone_name}/rrsets/#{rtype}/#{owner_name}", rrset)

    end

    def edit_rrset_profile(zone_name, rtype, owner_name, ttl, rdata, profile = {})
      rdata = [rdata] unless rdata.kind_of? Array
    
      rrset = {:ttl => ttl, :rdata => rdata, :profile => profile}
      @rest_api_connection.put("/v1/zones/#{zone_name}/rrsets/#{rtype}/#{owner_name}", rrset)
    
    end
  
    # Delete an rrset
    #
    # === Required Parameters
    # * +zone_name+ - The zone containing the RRSet to be deleted.  The trailing dot is optional.
    # * +rtype+ - The type of the RRSet.This can be numeric (1) or if a well-known name
    #              is defined for the type (A), you can use it instead.
    # * +owner_name+ - The owner name for the RRSet.
    #                   If no trailing dot is supplied, the owner_name is assumed to be relative (foo).
    #                   If a trailing dot is supplied, the owner name is assumed to be absolute (foo.zonename.com.)
    #
    # === Examples
    #
    #     c.delete_rrset(first_zone_name, 'A', 'foo')
    def delete_rrset(zone_name, rtype, owner_name)
      @rest_api_connection.delete "/v1/zones/#{zone_name}/rrsets/#{rtype}/#{owner_name}"
    end

    # Get account details for user
    #
    # === Examples
    #
    #     c.get_account_details
    def get_account_details
      @rest_api_connection.get '/v1/accounts'
    end

    # Get version of REST API server
    #
    # === Examples
    #
    #     c.version
    def version
      @rest_api_connection.get '/v1/version'
    end


    # Get status of REST API server
    #
    # === Examples
    #
    #     c.status
    def status
      @rest_api_connection.get '/v1/status'
    end

    private

    def build_params(args)
      params = {}
      if args[:q]
        q = args[:q]
        q_str = ''
        q.each { |k, v| q_str += "#{k}:#{v} " }
        if q_str.length > 0
          params[:q] = q_str
        end
        args.delete :q
      end
      params.update(args)
      params
    end
  end
end
