module APIUtils
  module Auth
    def session_from(service_name)
      if !@authorization
        authorization = request.env["HTTP_AUTHORIZATION"]
        token = authorization.scan(/^Bearer\s(.*)$/).flatten.first

        raise Unauthorized, 'Not enough permissions' unless token

        @session_data = Sessions.get_session(token)

        raise Unauthorized, 'Not enough permissions' unless @session_data["service"] == service_name
      end
    end
  end
end