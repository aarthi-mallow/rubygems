# frozen_string_literal: false
# = uri/wss.rb
#
# Author:: Matt Muller <mamuller@amazon.com>
# License:: You can redistribute it and/or modify it under the same term as Ruby.
#
# See CustomBundler::URI for general documentation
#

require_relative 'ws'

module CustomBundler::URI

  # The default port for WSS URIs is 443, and the scheme is 'wss:' rather
  # than 'ws:'. Other than that, WSS URIs are identical to WS URIs;
  # see CustomBundler::URI::WS.
  class WSS < WS
    # A Default port of 443 for CustomBundler::URI::WSS
    DEFAULT_PORT = 443
  end

  register_scheme 'WSS', WSS
end
