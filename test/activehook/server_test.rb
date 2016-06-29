require 'test_helper'

class Activehook::ServerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Activehook::Server::VERSION
  end
end
