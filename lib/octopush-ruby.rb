require 'octopush-ruby/configuration'
require 'octopush-ruby/constants'
require 'octopush-ruby/client'

module Octopush
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end
end
