require 'jwt'
require 'securerandom'

class Sessions
  def self.configure!(secret: nil, algorithm:)
    @secret = secret
    @algorithm = algorithm
  end

  def self.generate_session(payload = {})
    JWT.encode payload, @secret, @algorithm
  end

  def self.get_session(token)
    begin
      decoded = JWT.decode token, @secret, true, { algorithm: @algorithm }
    rescue => exception
      puts @secret, @algorithm
      raise Unauthorized, 'Not enough permissions'
    end

    decoded.first
  end
end