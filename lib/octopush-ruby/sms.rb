module Octopush
  class SMS
    attr_accessor :sms_text, :sms_recipients, :recipients_first_names,
                  :recipients_last_names, :sms_fields1, :sms_fields2,
                  :sms_fields3, :sms_mode, :sms_type, :sms_sender,
                  :request_mode, :request_id, :with_replies, :transactional,
                  :msisdn_sender

    def variables_hash
      hash = {}
      self.instance_variables.each do |variable|
        var = variable.to_s.sub('@', '')
        key = var.to_sym
        value = self.send(var)
        hash = hash.merge(key => value)
      end

      hash
    end

    def set_simulation_mode
      self.request_mode = @contants::REQUEST_MODES['SIMULATION']
    end
  end
end
