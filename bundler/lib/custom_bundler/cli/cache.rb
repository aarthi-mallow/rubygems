# frozen_string_literal: true

module CustomBundler
  class CLI::Cache
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      CustomBundler.ui.level = "warn" if options[:quiet]
      CustomBundler.settings.set_command_option_if_given :path, options[:path]
      CustomBundler.settings.set_command_option_if_given :cache_path, options["cache-path"]

      setup_cache_all
      install

      # TODO: move cache contents here now that all bundles are locked
      custom_path = CustomBundler.settings[:path] if options[:path]

      CustomBundler.settings.temporary(cache_all_platforms: options["all-platforms"]) do
        CustomBundler.load.cache(custom_path)
      end
    end

    private

    def install
      require_relative "install"
      options = self.options.dup
      options["local"] = false if CustomBundler.settings[:cache_all_platforms]
      options["no-cache"] = true
      CustomBundler::CLI::Install.new(options).run
    end

    def setup_cache_all
      all = options.fetch(:all, CustomBundler.feature_flag.cache_all? || nil)

      CustomBundler.settings.set_command_option_if_given :cache_all, all
    end
  end
end
