# frozen_string_literal: true

module CustomBundler
  def self.require_thor_actions
    require_relative "vendor/thor/lib/thor/actions"
  end
end
require_relative "vendor/thor/lib/thor"
