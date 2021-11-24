require 'net/http'
require 'nori'
require 'digest/sha1'
require 'httparty'
require 'octopush-ruby/sms'
require 'octopush-ruby/error/configuration_error'
require 'octopush-ruby/error/request_error'
require 'octopush-ruby/error/response_code_error'
require 'octopush-ruby/error/response_error'

module Octopush
  class Client
    def initialize
      raise Octopush::ConfigurationError.new("Should set user configuration before use") if Octopush.configuration.nil?

      @constants = Octopush::Constants
      @domain = @constants::DOMAIN
    end

    # update user options
    # args should be a hash with the options that you want to update
    # could be answer_email, sms_alert_bound, sms_alert_type
    # @example
    #   {answer_email: 'an_email@domain.com'}
    def edit_options *args
      path = @constants::PATH_EDIT_OPTIONS
      data = user_hash.merge args[0]
      res = request @domain, path, data
    end

    # returns current user's balance
    # return a hash in the form: {balance_type => balance}
    def get_balance
      path = @constants::PATH_BALANCE
      data = user_hash
      response = request @domain, path, data

      h = {}
      response["balance"].each do |balance|
        h = h.merge(balance.attributes["type"] => balance)
      end

      h
    end

    # Returns credit balance as a number of Euros left on account.
    # see http://www.octopush.com/en/api-sms-doc/get-credit
    def get_credit
      path = @constants::PATH_CREDIT
      data = user_hash
      request @domain, path, data
    end

    # send a sms
    #   sms - a Octopush::SMS instance
    #   sending_date - a date to send sms, required if sms_mode is DIFFERE,
    #                  check Octopush::Constants::SMS_MODES for modes allowed
    #   request_keys - Lists the key fields of the application you want to add
    #                  in the sha1 hash. Check Octopush::Constants::REQUEST_KEYS
    def send_sms sms, sending_date=nil, request_keys=nil
      raise 'require a sms object' if sms.class != Octopush::SMS

      path = @constants::PATH_SMS
      data = user_hash.merge(sms.variables_hash)

      if data[:sms_mode] == @constants::SMS_MODES['DIFFERE']
        raise 'Need specify sending_date for DIFFERE mode' if sending_date.nil?
        data = data.merge(sending_time: sending_date)
      end

      if !request_keys.nil?
        sha1 = get_request_sha1_string(request_keys)
        data = data.merge(request_keys: request_keys, request_sha1: sha1)
      end

      res = request @domain, path, data
    end

    # create sub account
    #   first_name
    #   last_name
    #   raison_sociable
    #   alert_bound
    #   alert_sms_type - check Octopush::Constants::SMS_TYPES
    def create_sub_account first_name, last_name, raison_sociable, alert_bound,
                           alert_sms_type
      path = @constants::PATH_SUB_ACCOUNT
      data = user_hash.merge( first_name: first_name,
                              last_name: last_name,
                              raison_sociable: raison_sociable,
                              alert_bound: alert_bound,
                              alert_sms_type: alert_sms_type
                            )
      res = request @domain, path, data
    end

    # credit sub account
    #   sub_account - sub account email
    #   sms_amount - number of credits
    #   sms_type - a sms type, check Octopush::Constants::SMS_TYPES
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
    end

    private

    def user_hash
      {
        user_login: Octopush.configuration.user_login,
        api_key: Octopush.configuration.api_key
        # sending_time: DateTime.now
      }
    end

    def request domain, path, data, ssl=true
      prefix = ssl ? 'https://' : 'http://'
      url = prefix + domain + path
      data_str = []
      data.each { |k,v| data_str << "#{k}=#{URI.encode(v)}" }
      url += '/?'
      url += data_str.join('&')
      res = HTTParty.post(url)
      if res.code != 200
        Octopush::ResponseError.new "Server returned with #{res.code} status code"
      else
        parse_response res.body
      end
    end

    # octopush api returns a xml after each request.
    # We parse the xml to hash for more easy use
    def parse_response response
      parser = Nori.new
      res_hash = parser.parse response
      code = res_hash["octopush"]["error_code"]
      if code != "000"
        raise Octopush::ResponseCodeError.new Octopush::Constants::ERRORS[code]
      else
        res_hash["octopush"]
      end
    end

    # get a sha1 string in base to request_keys
    def get_request_sha1_string request_keys, data
      char_to_field = @constants::REQUEST_KEYS
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
