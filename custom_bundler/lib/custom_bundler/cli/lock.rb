# frozen_string_literal: true

module CustomBundler
  class CLI::Lock
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      unless CustomBundler.default_gemfile
        CustomBundler.ui.error "Unable to find a Gemfile to lock"
        exit 1
      end

      print = options[:print]
      previous_ui_level = CustomBundler.ui.level
      CustomBundler.ui.level = "silent" if print

      CustomBundler::Fetcher.disable_endpoint = options["full-index"]

      update = options[:update]
      conservative = options[:conservative]
      bundler = options[:bundler]

      if update.is_a?(Array) # unlocking specific gems
        CustomBundler::CLI::Common.ensure_all_gems_in_lockfile!(update)
        update = { gems: update, conservative: conservative }
      elsif update && conservative
        update = { conservative: conservative }
      elsif update && bundler
        update = { bundler: bundler }
      end

      file = options[:lockfile]
      file = file ? Pathname.new(file).expand_path : CustomBundler.default_lockfile

      CustomBundler.settings.temporary(frozen: false) do
        definition = CustomBundler.definition(update, file)

        CustomBundler::CLI::Common.configure_gem_version_promoter(definition, options) if options[:update]

        options["remove-platform"].each do |platform|
          definition.remove_platform(platform)
        end

        options["add-platform"].each do |platform_string|
          platform = Gem::Platform.new(platform_string)
          if platform.to_s == "unknown"
            CustomBundler.ui.warn "The platform `#{platform_string}` is unknown to RubyGems " \
              "and adding it will likely lead to resolution errors"
          end
          definition.add_platform(platform)
        end

        if definition.platforms.empty?
          raise InvalidOption, "Removing all platforms from the bundle is not allowed"
        end

        definition.resolve_remotely! unless options[:local]

        if print
          puts definition.to_lock
        else
          puts "Writing lockfile to #{file}"
          definition.lock
        end
      end

      CustomBundler.ui.level = previous_ui_level
    end
  end
end
