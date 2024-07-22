# frozen_string_literal: true

module CustomBundler; end

# Use RubyGems vendored copy when available. Otherwise fallback to CustomBundler
# vendored copy. The vendored copy in CustomBundler can be removed once support for
# RubyGems 3.5 is dropped.

begin
  require "rubygems/vendor/uri/lib/uri"
rescue LoadError
  require_relative "vendor/uri/lib/uri"
  Gem::URI = CustomBundler::URI

  module Gem
    def URI(uri) # rubocop:disable Naming/MethodName
      CustomBundler::URI(uri)
    end
    module_function :URI
  end
end
