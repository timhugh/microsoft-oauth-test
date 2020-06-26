# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'hanami-router'
  gem 'httparty'
  gem 'pry'
  gem 'rack'
end

require 'json'

# Stuff specific to our oauth app
CLIENT_ID     = ENV['CLIENT_ID'].freeze
CLIENT_SECRET = ENV['CLIENT_SECRET'].freeze
TENANT_ID     = ENV['TENANT_ID'].freeze
SCOPE         = 'openid email profile User.Read'.freeze
# Other environment variables
PORT          = ENV['PORT'].to_i.freeze
CALLBACK_PATH = ENV['CALLBACK_PATH'].freeze
# Microsoft API routes
HOST          = 'https://login.microsoftonline.com'.freeze
AUTH_URL      = "#{HOST}/#{TENANT_ID}/oauth2/v2.0/authorize".freeze
TOKEN_URL     = "#{HOST}/#{TENANT_ID}/oauth2/v2.0/token".freeze
PROFILE_URL   = 'https://graph.microsoft.com/v1.0/me'.freeze
# This has to match the callback URL configured in active directory
REDIRECT_URL  = "https://localhost:#{PORT}#{CALLBACK_PATH}".freeze

app = Hanami::Router.new do
  def build_auth_url
    query_params = {
      client_id: CLIENT_ID,
      response_type: 'code',
      redirect_url: REDIRECT_URL,
      response_mode: 'query',
      scope: SCOPE
    }
    query_string = query_params.map do |k,v|
      "#{k}=#{CGI.escape(v)}"
    end.join('&')
    "#{AUTH_URL}?#{query_string}"
  end

  def parse_code_from_env(env)
    env["QUERY_STRING"]
      .split('&')
      .map { |kvstring| kvstring.split('=') }
      .to_h['code']
  end

  def get_token(code:)
    params = {
      client_id: CLIENT_ID,
      scope: SCOPE,
      code: code,
      redirect_url: REDIRECT_URL,
      grant_type: 'authorization_code',
      client_secret: CLIENT_SECRET
    }
    param_string = params.map do |k,v|
      "#{k}=#{CGI.escape(v)}"
    end.join('&')
    response = HTTParty.post(
      TOKEN_URL,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: param_string
    )
    response['access_token']
  end

  def get_profile(token:)
    response = HTTParty.get(
      PROFILE_URL,
      headers: {
        'Authorization' => "Bearer #{token}"
      }
    )
    response
  end

  redirect '/login', to: build_auth_url

  get CALLBACK_PATH, to: ->(env) do
    code = parse_code_from_env(env)
    token = get_token(code: code)
    profile = get_profile(token: token)
    [ 200, {}, [profile.to_s] ]
  end
end

Rack::Server.start app: app, Port: PORT
