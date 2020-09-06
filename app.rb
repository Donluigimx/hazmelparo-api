require 'sinatra/base'
require 'sinatra/namespace'

require_relative './helpers/validator.rb'
require_relative './helpers/responses.rb'
require_relative './helpers/errors.rb'
require_relative './helpers/error_handler.rb'
require_relative './helpers/sessions.rb'
require_relative './helpers/auth.rb'

require_relative './lib/udeg.rb'

class App < Sinatra::Base
  register Sinatra::Namespace
  register APIUtils::ErrorHandler

  helpers APIUtils::Auth
  helpers APIUtils::Validator
  helpers APIUtils::Responses

  def self.register_routes!(&block)
    namespace '/api/v1' do
      instance_eval(&block)
    end
  end

  configure do
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, false
    set :logging, false 

    Sessions.configure!(secret: ENV['SESSION_SECRET'], algorithm: ENV['SESSION_ALGORITHM'])
  end
end

# Load routes from path below
for file in Dir['./api/*.rb'] do
  require(file)
end