# frozen_string_literal: false
# CustomBundler::URI is a module providing classes to handle Uniform Resource Identifiers
# (RFC2396[http://tools.ietf.org/html/rfc2396]).
#
# == Features
#
# * Uniform way of handling URIs.
# * Flexibility to introduce custom CustomBundler::URI schemes.
# * Flexibility to have an alternate CustomBundler::URI::Parser (or just different patterns
#   and regexp's).
#
# == Basic example
#
#   require 'bundler/vendor/uri/lib/uri'
#
#   uri = CustomBundler::URI("http://foo.com/posts?id=30&limit=5#time=1305298413")
#   #=> #<CustomBundler::URI::HTTP http://foo.com/posts?id=30&limit=5#time=1305298413>
#
#   uri.scheme    #=> "http"
#   uri.host      #=> "foo.com"
#   uri.path      #=> "/posts"
#   uri.query     #=> "id=30&limit=5"
#   uri.fragment  #=> "time=1305298413"
#
#   uri.to_s      #=> "http://foo.com/posts?id=30&limit=5#time=1305298413"
#
# == Adding custom URIs
#
#   module CustomBundler::URI
#     class RSYNC < Generic
#       DEFAULT_PORT = 873
#     end
#     register_scheme 'RSYNC', RSYNC
#   end
#   #=> CustomBundler::URI::RSYNC
#
#   CustomBundler::URI.scheme_list
#   #=> {"FILE"=>CustomBundler::URI::File, "FTP"=>CustomBundler::URI::FTP, "HTTP"=>CustomBundler::URI::HTTP,
#   #    "HTTPS"=>CustomBundler::URI::HTTPS, "LDAP"=>CustomBundler::URI::LDAP, "LDAPS"=>CustomBundler::URI::LDAPS,
#   #    "MAILTO"=>CustomBundler::URI::MailTo, "RSYNC"=>CustomBundler::URI::RSYNC}
#
#   uri = CustomBundler::URI("rsync://rsync.foo.com")
#   #=> #<CustomBundler::URI::RSYNC rsync://rsync.foo.com>
#
# == RFC References
#
# A good place to view an RFC spec is http://www.ietf.org/rfc.html.
#
# Here is a list of all related RFC's:
# - RFC822[http://tools.ietf.org/html/rfc822]
# - RFC1738[http://tools.ietf.org/html/rfc1738]
# - RFC2255[http://tools.ietf.org/html/rfc2255]
# - RFC2368[http://tools.ietf.org/html/rfc2368]
# - RFC2373[http://tools.ietf.org/html/rfc2373]
# - RFC2396[http://tools.ietf.org/html/rfc2396]
# - RFC2732[http://tools.ietf.org/html/rfc2732]
# - RFC3986[http://tools.ietf.org/html/rfc3986]
#
# == Class tree
#
# - CustomBundler::URI::Generic (in uri/generic.rb)
#   - CustomBundler::URI::File - (in uri/file.rb)
#   - CustomBundler::URI::FTP - (in uri/ftp.rb)
#   - CustomBundler::URI::HTTP - (in uri/http.rb)
#     - CustomBundler::URI::HTTPS - (in uri/https.rb)
#   - CustomBundler::URI::LDAP - (in uri/ldap.rb)
#     - CustomBundler::URI::LDAPS - (in uri/ldaps.rb)
#   - CustomBundler::URI::MailTo - (in uri/mailto.rb)
# - CustomBundler::URI::Parser - (in uri/common.rb)
# - CustomBundler::URI::REGEXP - (in uri/common.rb)
#   - CustomBundler::URI::REGEXP::PATTERN - (in uri/common.rb)
# - CustomBundler::URI::Util - (in uri/common.rb)
# - CustomBundler::URI::Error - (in uri/common.rb)
#   - CustomBundler::URI::InvalidURIError - (in uri/common.rb)
#   - CustomBundler::URI::InvalidComponentError - (in uri/common.rb)
#   - CustomBundler::URI::BadURIError - (in uri/common.rb)
#
# == Copyright Info
#
# Author:: Akira Yamada <akira@ruby-lang.org>
# Documentation::
#   Akira Yamada <akira@ruby-lang.org>
#   Dmitry V. Sabanin <sdmitry@lrn.ru>
#   Vincent Batts <vbatts@hashbangbash.com>
# License::
#  Copyright (c) 2001 akira yamada <akira@ruby-lang.org>
#  You can redistribute it and/or modify it under the same term as Ruby.
#

module CustomBundler::URI
end

require_relative 'uri/version'
require_relative 'uri/common'
require_relative 'uri/generic'
require_relative 'uri/file'
require_relative 'uri/ftp'
require_relative 'uri/http'
require_relative 'uri/https'
require_relative 'uri/ldap'
require_relative 'uri/ldaps'
require_relative 'uri/mailto'
require_relative 'uri/ws'
require_relative 'uri/wss'
