module APIUtils
  module Validator
    def get_data(key)
      @value = nil
      if @body.nil?
        request.body.rewind
        body = request.body.read
        if request.accept? 'application/json'
          @body = (body.nil? || body.empty?) ? {} : (JSON.parse(body, symbolize_names: true) rescue nil)  
        end
      end

      @value = @body[key]
      yield
      @value
    end

    def matches(regex)
      is_valid = @value.match(regex)
      raise BadRequest unless is_valid
    end

    def min_size(size)
      is_valid = @value.size > size
      raise BadRequest unless is_valid
    end

    def max_size(size)
      is_valid = @value.size < size
      raise BadRequest unless is_valid
    end

    def is_required()
      raise BadRequest if @value.nil?
    end
  end
end