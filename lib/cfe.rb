require 'net/http'
require 'uri'

class CFE
  class << self
    attr_reader :base
  end

  @base = "https://app.cfe.mx"

  def initialize(cookies:)
    @cookies = cookies
    puts @cookies
  end

  def self.get(path, cookies: nil)
    uri = URI.join(CFE.base, path)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Cookie"] = cookies if cookies
    response = https.request(request)

    return {
      status_code: response.code,
      body: response.body,
      headers: response.to_hash,
    }
  end

  def self.post(path, cookies: nil, data: nil)
    uri = URI.join(CFE.base, path)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-www-form-urlencoded" if data
    request["Cookie"] = cookies if cookies
    request.body = URI.encode_www_form(data) if data
    response = https.request(request)

    return {
      status_code: response.code,
      body: response.body,
      headers: response.to_hash,
    }
  end

  def self.get_body_states(body)
    view_state = body.match(/id="__VIEWSTATE".+?value="([^"]+?)"/)[1]
    view_state_generator = body.match(/id="__VIEWSTATEGENERATOR".+?value="([^"]+?)"/)[1]
    event_validation = body.match(/id="__EVENTVALIDATION".+?value="([^"]+?)"/)[1]

    return {
      view_state: view_state,
      view_state_generator: view_state_generator,
      event_validation: event_validation
    }
  end

  def self.with_login(user:, password:)
    response = CFE.get('/Aplicaciones/CCFE/MiEspacio/Login.aspx')
    body = response[:body]

    view_state = body.match(/id="__VIEWSTATE".+?value="([^"]+?)"/)[1]
    view_state_generator = body.match(/id="__VIEWSTATEGENERATOR".+?value="([^"]+?)"/)[1]
    event_validation = body.match(/id="__EVENTVALIDATION".+?value="([^"]+?)"/)[1]

    response = CFE.post(
      '/Aplicaciones/CCFE/MiEspacio/Login.aspx',
      data: {
        '__VIEWSTATE': view_state,
        '__VIEWSTATEGENERATOR': view_state_generator,
        '__VIEWSTATEENCRYPTED': '',
        '__EVENTVALIDATION': event_validation,
        'ctl00$MainContent$txtUsuario': user,
        'ctl00$MainContent$txtPassword': password,
        'ctl00$MainContent$btnIngresar': 'Ingresar'
      }
    )

    cookies = response[:headers]['set-cookie'].first

    # Gets AntiXSRF Token
    response = CFE.get('/Aplicaciones/CCFE/MiEspacio/default.aspx', cookies: cookies)
    cookies = [cookies, *response[:headers]['set-cookie']].join('; ')

    return CFE.new(cookies: cookies)
  end

  def add_service(service_number:, service_name:, service_amount:, service_alias:)
    response = CFE.get('/Aplicaciones/CCFE/MiEspacio/AgregarServicio.aspx', cookies: @cookies)
    events = CFE.get_body_states(response[:body])
    response = CFE.post(
      '/Aplicaciones/CCFE/MiEspacio/AgregarServicio.aspx',
      cookies: @cookies,
      data: {
        '__EVENTTARGET': '',
        '__EVENTARGUMENT': '',
        '__VIEWSTATE': events[:view_state],
        '__VIEWSTATEGENERATOR': events[:view_state_generator],
        '__VIEWSTATEENCRYPTED': '',
        '__EVENTVALIDATION': events[:event_validation],
        'q': '',
        'ctl00$MainContent$txtRpu': service_number,
        'ctl00$MainContent$txtNombreServicio': service_name,
        'ctl00$MainContent$txtTotalAPagar': service_amount,
        'ctl00$MainContent$txtNombreCorto': service_alias,
        'ctl00$MainContent$btnGuardar': 'Guardar'
      }
    )

    if response[:body] =~ /id="ctl00_MainContent_lblError"/
      raise 'Wrong information'
    end

    puts response[:body]
  end
end
