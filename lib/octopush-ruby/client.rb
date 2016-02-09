require 'net/http'
require 'nori'
require 'digest/sha1'
require 'octopush-ruby/sms'

module Octopush
  class Client
    def initialize
      raise "Should set user configuration before use" if Octopush.configuration.nil?

      @constants = Octopush::Constants
      @domain = @constants::DOMAIN
    end

    def edit_options *args
      path = PATH_EDIT_OPTIONS
      data = user_hash.merge args
      res = request @domain, path, data
      parse_response res.body
    end

    def get_balance
      # return a hash in the form: {balance_type => balance}
      path = @constants::PATH_BALANCE
      data = user_hash
      response = request @domain, path, data

      h = {}
      response["balance"].each do |balance|
        h = h.merge(balance.attributes["type"] => balance)
      end

      h
    end

    def send_sms sms, sending_date=nil, request_keys=nil
      raise 'require a sms object' if sms.class != Octopush::SMS

      path = PATH_SMS
      data = user_hash.merge(sms.variables_hash)

      if data[:sms_mode] == 'DIFFERE'
        raise 'Need specify sending_date for DIFFERE mode' if sending_date.nil?
        data = data.merge(sending_date: sending_date)
      end

      if !request_keys.nil?
        sha1 = get_request_sha1_string(request_keys)
        data = data.merge(request_keys: request_keys, request_sha1: sha1)
      end

      res = request @domain, path, data
      parse_response res.body
    end

    # sub account
    def create_sub_account first_name, last_name, raison_sociable, alert_bound,
                           alert_sms_type
      path = PATH_SUB_ACCOUNT
      data = user_hash.merge( first_name: first_name,
                              last_name: last_name,
                              raison_sociable: raison_sociable,
                              alert_bound: alert_bound,
                              alert_sms_type: alert_sms_type
                            )

      res = request @domain, path, data
      parse_response res.body
    end

    def credit_sub_account sub_account_email, sms_amount, sms_type
      path = @constants::PATH_CREDIT_SUB_ACCOUNT_TOKEN
      data = user_hash.merge(sub_account_email: sub_account_email)
      res = request @domain, path, data
      token_res = parse_response res.body

      token = token_res['token']
      path = @constants::PATH_CREDIT_SUB_ACCOUNT
      if sms_type != 'FR' and sms_type != 'XXX'
        sms_type = 'FR'
      end

      data = data.merge(sms_number: sms_amount,
                        sms_type: sms_type,
                        token: token)

      res = request @domain, path, data
      parse_response res.body
    end

    private

    def user_hash
      {
        user_login: Octopush.configuration.user_login,
        api_key: Octopush.configuration.api_key
      }
    end

    def request domain, path, data, ssl=false
      prefix = ssl ? 'https://' : 'http://'
      url = prefix + domain + path
      uri = URI url
      req = Net::HTTP::Post.new uri.path
      req.set_form_data data
      res = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(req)
      end
      parse_response res.body
    end

    def parse_response response
      parser = Nori.new
      res_hash = parser.parse response
      code = res_hash["octopush"]["error_code"]
      if code != "000"
        raise Octopush::Constants::ERRORS[code]
      else
        res_hash["octopush"]
      end
    end

    def get_request_sha1_string request_keys, data
      char_to_field = {
        'T'	 => 'sms_text',
        'R'	 => 'sms_recipients',
        'M'	 => 'sms_mode',
        'Y'	 => 'sms_type',
        'S'	 => 'sms_sender',
        'D'	 => 'sms_date',
        'a'	 => 'recipients_first_names',
        'b'	 => 'recipients_last_names',
        'c'	 => 'sms_fields_1',
        'd'	 => 'sms_fields_2',
        'e'	 => 'sms_fields_3',
        'W'	 => 'with_replies',
        'N'	 => 'transactional',
        'Q'	 => 'request_id'
      }

      request_string = ''
      request_keys.split('').each do |key|
        if !char_to_field[key].nil? and !data[char_to_field[key].to_sym].nil?
          request_string += data[char_to_field[key].to_sym]
        end
      end

      Digest::SHA1.hexdigest request_string
    end
  end
end
