App.register_routes! do
  namespace '/siiau' do
    post '/login' do
      nip = get_data(:nip) { is_required && matches(/^\d{2,9}$/) } 
      password = get_data(:password) { is_required && max_size(20) }

      siiau = nil

      begin
        siiau = SIIAU.new(nip: nip, password: password)
      rescue => exception
        puts exception
        raise BadRequest, 'Error trying to login'
      end
      degrees = siiau.menu

      success_response degrees
    end

    post '/student_proof' do
      nip = get_data(:nip) { is_required && matches(/^\d{2,9}$/) } 
      password = get_data(:password) { is_required && max_size(20) }
      degree = get_data(:degree) { is_required }

      siiau = nil

      begin
        siiau = SIIAU.new(nip: nip, password: password)
      rescue => exception
        puts exception
        raise BadRequest, 'Error trying to login'
      end

      student_proof = siiau.student_proof(degree)
      success_response student_proof
    end
  end
end