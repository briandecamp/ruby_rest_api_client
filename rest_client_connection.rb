module UltraRestApi

  require 'faraday'
  require 'json'

  class RestClientConnection
    def initialize(use_http = false, host= 'restapi.ultradns.com')
      @use_http = use_http
      @host = host
      @access_token = ''
      @refresh_token = ''
      get_connection
    end

    def auth(username, password)
      response = @client.post ('/v1/authorization/token') do |request|
        request.params[:grant_type]='password'
        request.params[:username]=username
        request.params[:password]=password
      end
      body = JSON.parse(response.body)
      if response.status == 200
        @access_token = body['accessToken']
        @refresh_token = body['refreshToken']
      else
        raise response.body
      end
    end

    %w[get head delete].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url, params = {}, retry_call = true)
          headers = {:content_type=>'application/json', :Authorization=>"Bearer \#{@access_token}"}
          response = @client.#{method}(url, params, headers)
          body = {}
          if response.body != nil && response.body != ''
            body = JSON.parse(response.body)
            if body.is_a?(Hash) && retry_call && (response.status == 400 || response.status == 401) && body["errorCode"] == 60001
              refresh
              return #{method}(url, params, false)
            end
          end
          if response.status >= 400
            raise response.body
          end
          body
        end
      RUBY
    end

    %w[post put patch].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url, in_body = {}, retry_call = true)
          headers = {:content_type=>'application/json', :Authorization=>"Bearer \#{@access_token}"}
          response = @client.#{method}(url, in_body.to_json, headers)
          body = {}
          if response.body != nil && response.body != ''
            body = JSON.parse(response.body)
            if body.is_a?(Hash) && retry_call && (response.status == 400 || response.status == 401) && body["errorCode"] == 60001
              refresh
              return #{method}(url, in_body, false)
            end
          end
          if response.status >= 400
            raise response.body
          end
          body
        end
      RUBY
    end

    private

    def get_connection
      protocol = @use_http ? 'http' : 'https'
      base_url = "#{protocol}://#{@host}"
      @client = Faraday.new(:url => base_url) do |c|
        c.use Faraday::Request::UrlEncoded # encode request params as "www-form-urlencoded"
        #c.use Faraday::Response::Logger # log request & response to STDOUT
        c.use Faraday::Adapter::NetHttp # perform requests with Net::HTTP
      end
    end

    def refresh
      response = @client.post('/v1/authorization/token') do |request|
        request.params[:grant_type]='refresh_token'
        request.params[:refreshToken]=@refresh_token
      end
      if response.status == 200
        json_body = JSON.parse(response.body)
        @access_token = json_body['accessToken']
        @refresh_token = json_body['refreshToken']
      else
        raise response.body
      end
    end
  end
end


