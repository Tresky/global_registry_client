require 'rest-client'
require 'oj'
require 'retryable'

module GlobalRegistry
  class Base
    def initialize(args = {})
      @base_url = args[:base_url]
      @access_token = args[:access_token]
    end

    def self.find(id, params = {})
      request(:get, params, path_with_id(id))
    end
    def find(id, params = {})
      request(:get, params, path_with_id(id))
    end

    def self.get(params = {})
      request(:get, params)
    end
    def get(params = {})
      request(:get, params)
    end

    def self.post(params = {})
      request(:post, params)
    end
    def post(params = {})
      request(:post, params)
    end

    def self.put(id, params = {})
      request(:put, params, path_with_id(id))
    end
    def put(id, params = {})
      request(:put, params, path_with_id(id))
    end

    def self.delete(id)
      request(:delete, {}, path_with_id(id))
    end
    def delete(id)
      request(:delete, {}, path_with_id(id))
    end

    def self.delete_or_ignore(id)
      begin
        delete(id)
      rescue RestClient::Exception => e
        unless e.response.code.to_i == 404
          raise
        end
      end
    end


    def self.request(method, params, path = nil)
      new.request(method, params, path)
    end

    def request(method, params, path = nil)
      raise 'You need to configure GlobalRegistry with your access_token.' unless access_token

      path ||= self.class.default_path
      url = base_url
      url += '/' unless url.last == '/'
      url += path

      case method
      when :post
        post_headers = { content_type: :json, accept: :json, authorization: "Bearer #{access_token}", timeout: -1 }
        RestClient.post(url, params.to_json, post_headers) { |response, request, result, &block|
          handle_response(response, request, result)
        }
      when :put
        put_headers = { content_type: :json, accept: :json, authorization: "Bearer #{access_token}", timeout: -1 }
        RestClient.put(url, params.to_json, put_headers) { |response, request, result, &block|
          handle_response(response, request, result)
        }
      else
        get_args = { method: method, url: url, timeout: -1,
                     headers: { params: params, authorization: "Bearer #{access_token}", accept: :json }
                   }
        RestClient::Request.execute(get_args) { |response, request, result, &block|
          handle_response(response, request, result)
        }
      end
    end

    def self.default_path
      to_s.split('::').last.underscore.pluralize
    end

    def self.path_with_id(id)
      "#{default_path}/#{id}"
    end

    private

    def handle_response(response, request, result)
      case response.code
      when 200..299
        Oj.load(response)
      when 400
        raise RestClient::BadRequest, response
      when 404
        raise RestClient::ResourceNotFound, response
      when 500
        raise RestClient::InternalServerError, response
      else
        puts response.inspect
        puts request.inspect
        raise result.to_s
      end
    end

    def base_url
      @base_url || GlobalRegistry.base_url
    end

    def access_token
      @access_token || GlobalRegistry.access_token
    end
  end
end




