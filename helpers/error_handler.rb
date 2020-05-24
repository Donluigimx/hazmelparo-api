module APIUtils
  module ErrorHandler
    def self.registered(app)
      app.error BadRequest do |error|
        error_response(
          status_code: 400,
          message: error.message,
          code: 'BAD_REQUEST'
        )
      end

      app.error NotFound do |error|
        error_response(
          status_code: 404,
          message: error.message,
          code: 'NOT_FOUND'
        )
      end
      
      app.error Unauthorized do |error|
        error_response(
          status_code: 401,
          message: error.message,
          code: 'UNAUTHORIZED'
        )
      end

      app.error do |error|
        error_response(
          status_code: 500,
          message: 'Internal Server Error',
          code: 'INTERNAL_SERVER_ERROR'
        )
      end
    end
  end
end