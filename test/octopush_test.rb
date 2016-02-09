require_relative 'helper'
include Octopush

scope do
  setup do
    Octopush.configure do |c|
      c.user_login = 'mymail@example.com'
    end
  end

  test "sha1 string" do
    data = {sms_text: 'fasgsagasg'}
    cli = Octopush::Client.new
    sha1 = cli.send(:get_request_sha1_string, 'T', data)
    assert_equal "4ba873f39c4ca45c67ab281e75ca23779d72bf2a", sha1

    data = {sms_text: 'fasgsagasg', sms_recipients: '+51948372820'}
    cli = Octopush::Client.new
    sha1 = cli.send(:get_request_sha1_string, 'TR', data)
    assert_equal "53dfcf057931579e382e76a96f79e32d3d01c014", sha1
  end
end
