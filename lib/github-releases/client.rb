require 'json'
require 'faraday'
require 'uri'

module GithubReleases
  class Client

    def initialize(owner, repository, gh_token = nil)
      @client = Faraday::Connection.new(:url => 'https://api.github.com') do |builder|
        builder.request  :url_encoded
        builder.response :logger
        builder.adapter  :net_http
      end
      @owner = owner
      @repository = repository
      @gh_token = gh_token
    end

    def get(id = nil)
      res = nil
      if id
        res = @client.get url
      else
        res = @client.get url(id)
      end
      JSON.parse res.body
    end

    def release(tag_name, params = {}) 
      raise 'Require Github Token' unless @gh_token

      params[:tag_name] = tag_name
      res = @client.post do |req|
        req.url url
        req.headers['Accept']        = 'application/json'
        req.headers['Content-Type']  = 'application/json'
        req.headers['Authorization'] = "token #{@gh_token}"
        req.body = params.to_json
      end
      JSON.parse res.body
    end

    def attach(id, path)
      raise 'Require Github Token' unless @gh_token
      raise 'File Not Found' unless File.exists?(path)
      
      upload = Faraday::Connection.new(:url => 'https://uploads.github.com') do |builder|
        builder.request  :url_encoded
        builder.response :logger
        builder.adapter  :net_http
      end
      
      res = upload.post do |req|
        req.url "#{url(id)}/assets?name=#{File.basename(path)}"
        req.headers['Accept']        = 'application/json'
        req.headers['Content-Type']  = 'application/octet-stream'
        req.headers['Authorization'] = "token #{@gh_token}"
        req.body = File.open(path, 'rb').read
      end
      JSON.parse res.body
    end

    private
    def url(id = nil)
      if id
        "/repos/#{@owner}/#{@repository}/releases/#{id}"
      else
        "/repos/#{@owner}/#{@repository}/releases"
      end
    end
  end
end
