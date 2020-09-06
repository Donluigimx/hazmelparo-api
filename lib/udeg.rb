require 'net/http'
require 'uri'
require 'httparty'

class SIIAU
  class << self
    attr_reader :base
  end

  @base = 'http://siiauescolar.siiau.udg.mx'

  def initialize(cookies:, siiau_id:)
    @cookies = cookies
    @siiau_id = siiau_id
  end

  def self.with_login(nip:, password:)
    uri = URI.join(SIIAU.base, '/wus/gupprincipal.valida_inicio')
    response = HTTParty.post(
      uri,
      body: URI.encode_www_form(
        p_codigo_c: nip,
        p_clave_c: password
      ),
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    )

    raise 'Login error' if response.response.code != '200' || response.body =~ /error/

    cookies = build_cookie response.headers['set-cookie']
    siiau_id = response.headers['set-cookie'].match(/SIIAUUDG=([^;]+?);/)[1]
    SIIAU.new(cookies: cookies, siiau_id: siiau_id)
  end

  def self.with_session(session)
    SIIAU.new(cookies: session["cookies"], siiau_id: session["siiau_id"])
  end

  def self.build_cookie(cookies)
    cookies
      .scan(/(?:([\w\d]+?=[\w\d]+);)/)
      .flatten
      .join('; ')
  end

  def get_session()
    {
      cookies: @cookies,
      siiau_id: @siiau_id,
      service: 'SIIAU'
    }
  end

  def menu()
    uri = URI.join(SIIAU.base, "/wal/gupmenug.menu?#{URI.encode_www_form(
      p_sistema_c: 'ALUMNOS',
      p_sistemaid_n: 3,
      p_menupredid_n: 3,
      p_pidm_n: @siiau_id,
      p_majr_c: @siiau_id
    )}")

    response = HTTParty.get(
      uri,
      headers: {
        'Cookie' => @cookies
      }
    )

    response
      .body
      .match(/<SELECT[^>]*NAME="p_carrera"(?:[^\/]+?)<\/SELECT>/) { |matched|
        @degrees = matched
          .to_s
          .scan(/<OPTION[^>]*value="([^"]+?)"/)
          .flatten
      }
    
    @degrees
  end

  def student_proof(degree)
    degree_name, degree_cycle = degree.match(/(.+?)-(.+)/)[1,2]

    uri = URI.join(SIIAU.base, "/wal/sgphist.constancia?#{URI.encode_www_form(
      pidmp: @siiau_id,
      majrp: degree_name,
      cicloap: degree_cycle
    )}")

    puts uri

    response = HTTParty.get(
      uri,
      headers: {
        'Cookie': @cookies
      }
    )

    data = {}

    # Gets courses data
    response
      .body
      .match(/CICLO(?:.|[\w\d\s\n\t\r])+?(?=<\/TABLE)/) { |matched|
        data[:courses] = []

        values = matched
          .to_s
          .scan(/<FONT[^>]+>([^<]+)/)
          .flatten
        
        while values.length > 0
          course, credits, grade_number, grade_name, cycle = values[0,5]
          values.shift(5)

          data[:courses].push(
            course: course,
            credits: credits,
            grade_number: grade_number,
            grade_name: grade_name,
            cycle: cycle
          )
        end
      }
    
    response
      .body
      .match(/DATOS DEL ESTUDIANTE(?:[^<]|<)+?TABLE([^\/]|\/)+?TABLE/) {|matched|
        data[:student] = {}

        values = matched
          .to_s
          .scan(/<TD[^<]+<FONT[^>]+>([^<]+)/)
          .flatten

        %i{
          code
          name
          status
          degree_level
          degree_first_cycle
          degree_last_cycle
          degree_name
          campus
          campus_location
        }.each_with_index {|key, index|
          data[:student][key] = values[index]
        }
      }
      
    data
  end
end
