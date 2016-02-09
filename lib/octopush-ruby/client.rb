require 'net/http'
require 'nori'

module Octopush
  class Client
    attr_accessor :sms_text, :sms_recipients, :recipients_first_names,
                  :recipients_last_names, :sms_fields1, :sms_fields2,
                  :sms_fields3, :sms_mode, :sms_type, :sms_sender,
                  :request_mode, :request_id, :with_replies, :transactional,
                  :msisdn_sender

    def initialize
      raise "Should set user configuration before use" if Octopush.configuration.nil?
      # define set_"attribute" methods
      instance_variables.each do |attribute|
        str = attribute.to_s.gsub /^@/, ''
        if respond_to? "#{str}="
          define_method "set_#{str}" do |value|
            self.send("#{str}=", value)
          end
        end
      end

      @constants = Octopush::Constants
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

    def edit_options
    end

    def get_balance
      # return a hash in the form: {balance_type => balance}
      domain = @constants::DOMAIN
      path = @constants::PATH_BALANCE
      data = user_hash
      response = request domain, path, data

      h = {}
      response["balance"].each do |balance|
        h = h.merge(balance.attributes["type"] => balance)
      end

      h
    end

    def user_hash
      {
        user_login: Octopush.configuration.user_login,
        api_key: Octopush.configuration.api_key
      }
    end

    def parse_response response
      parser = Nori.new
      res_hash = parser.parse response
      code = res_hash["octopush"]["error_code"]
      if code != "000"
        raise Octopush::Constants::ERRORS[code.to_sym]
      else
        res_hash["octopush"]
      end
    end

    def send_sms sms_text, recipients
    end

    # sub account
    def create_sub_account
    end

    def credit_sub_account sub_account_email, sms_amount, sms_type
    end

    def get_request_sha1_string
    end
  end
end
