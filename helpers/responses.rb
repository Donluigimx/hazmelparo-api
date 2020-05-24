module APIUtils
  module Responses
    def clean_value(body, index)
      case body[index]
      when Float
        body[index] = body[index].to_i if body[index].to_s =~ /\.0$/
      when Integer
        return
      when FalseClass
      when TrueClass
      when Hash
        clean_body(body[index])
      when Array
        clean_body(body[index])
      when NilClass
      when String
      when Time
        body[index] = body[index].to_s
      else
        puts 'Not handled'
      end
    end

    def clean_body(body)
      if body.is_a?(Hash)
        body.each { |key, value| clean_value(body, key) }
      elsif body.is_a?(Array)
        body.each_with_index { |value, index| clean_value(body, index) }
      else
        puts 'Not hanlded'
      end
    end

    def success_response(response_body = {})
      if request.accept? 'application/json'
        response.headers['Content-Type'] = 'application/json'

        clean_body response_body
        halt 200, response_body.to_json
      end
    end

    def error_response(error)
      if request.accept? 'application/json'
        response.headers['Content-Type'] = 'application/json'
        body = {
          error: {
            statusCode: error[:status_code] || 500,
            name: 'Error',
            message: error[:message] || 'Unknown Error',
            code: error[:code] || 'UNKNOWN_ERROR',
          }
        }

        clean_body body
        halt error[:status_code], body.to_json
      end
    end
  end
end