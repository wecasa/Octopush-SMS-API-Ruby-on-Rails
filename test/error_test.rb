require_relative "helper"
include Octopush

scope do
  test "configuration error" do
    assert_raise(Octopush::ConfigurationError) { Octopush::Client.new }
  end
end
