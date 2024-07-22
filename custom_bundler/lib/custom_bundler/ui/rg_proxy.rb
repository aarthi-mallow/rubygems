# frozen_string_literal: true

require_relative "../ui"
require "rubygems/user_interaction"

module CustomBundler
  module UI
    class RGProxy < ::Gem::SilentUI
      def initialize(ui)
        @ui = ui
        super()
      end

      def say(message)
        @ui&.debug(message)
      end
    end
  end
end
