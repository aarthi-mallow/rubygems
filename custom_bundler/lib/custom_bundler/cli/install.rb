# frozen_string_literal: true

module CustomBundler
  class CLI::Install
    attr_reader :options
    def initialize(options)
      @options = options
    end

    def run
      CustomBundler.ui.level = "warn" if options[:quiet]

      warn_if_root

      CustomBundler.self_manager.install_locked_bundler_and_restart_with_it_if_needed

      CustomBundler::SharedHelpers.set_env "RB_USER_INSTALL", "1" if Gem.freebsd_platform?

      # Disable color in deployment mode
      CustomBundler.ui.shell = Thor::Shell::Basic.new if options[:deployment]

      if target_rbconfig_path = options[:"target-rbconfig"]
        CustomBundler.rubygems.set_target_rbconfig(target_rbconfig_path)
      end

      check_for_options_conflicts

      check_trust_policy

      if options[:deployment] || options[:frozen] || CustomBundler.frozen_bundle?
        unless CustomBundler.default_lockfile.exist?
          flag   = "--deployment flag" if options[:deployment]
          flag ||= "--frozen flag"     if options[:frozen]
          flag ||= "deployment setting"
          raise ProductionError, "The #{flag} requires a lockfile. Please make " \
                                 "sure you have checked your #{SharedHelpers.relative_lockfile_path} into version control " \
                                 "before deploying."
        end

        options[:local] = true if CustomBundler.app_cache.exist?

        CustomBundler.settings.set_command_option :deployment, true if options[:deployment]
        CustomBundler.settings.set_command_option :frozen, true if options[:frozen]
      end

      # When install is called with --no-deployment, disable deployment mode
      if options[:deployment] == false
        CustomBundler.settings.set_command_option :frozen, nil
        options[:system] = true
      end

      normalize_settings

      CustomBundler::Fetcher.disable_endpoint = options["full-index"]

      if options["binstubs"]
        CustomBundler::SharedHelpers.major_deprecation 2,
          "The --binstubs option will be removed in favor of `bundle binstubs --all`",
          removed_message: "The --binstubs option have been removed in favor of `bundle binstubs --all`"
      end

      Plugin.gemfile_install(CustomBundler.default_gemfile) if CustomBundler.feature_flag.plugins?

      definition = CustomBundler.definition
      definition.validate_runtime!

      installer = Installer.install(CustomBundler.root, definition, options)

      CustomBundler.settings.temporary(cache_all_platforms: options[:local] ? false : CustomBundler.settings[:cache_all_platforms]) do
        CustomBundler.load.cache(nil, options[:local]) if CustomBundler.app_cache.exist? && !options["no-cache"] && !CustomBundler.frozen_bundle?
      end

      CustomBundler.ui.confirm "Bundle complete! #{dependencies_count_for(definition)}, #{gems_installed_for(definition)}."
      CustomBundler::CLI::Common.output_without_groups_message(:install)

      if CustomBundler.use_system_gems?
        CustomBundler.ui.confirm "Use `bundle info [gemname]` to see where a bundled gem is installed."
      else
        relative_path = CustomBundler.configured_bundle_path.base_path_relative_to_pwd
        CustomBundler.ui.confirm "Bundled gems are installed into `#{relative_path}`"
      end

      CustomBundler::CLI::Common.output_post_install_messages installer.post_install_messages

      warn_ambiguous_gems

      if CLI::Common.clean_after_install?
        require_relative "clean"
        CustomBundler::CLI::Clean.new(options).run
      end

      CustomBundler::CLI::Common.output_fund_metadata_summary
    rescue Gem::InvalidSpecificationException
      CustomBundler.ui.warn "You have one or more invalid gemspecs that need to be fixed."
      raise
    end

    private

    def warn_if_root
      return if CustomBundler.settings[:silence_root_warning] || Gem.win_platform? || !Process.uid.zero?
      CustomBundler.ui.warn "Don't run CustomBundler as root. Installing your bundle as root " \
                      "will break this application for all non-root users on this machine.", wrap: true
    end

    def dependencies_count_for(definition)
      count = definition.dependencies.count
      "#{count} Gemfile #{count == 1 ? "dependency" : "dependencies"}"
    end

    def gems_installed_for(definition)
      count = definition.specs.count
      "#{count} #{count == 1 ? "gem" : "gems"} now installed"
    end

    def check_for_group_conflicts_in_cli_options
      conflicting_groups = Array(options[:without]) & Array(options[:with])
      return if conflicting_groups.empty?
      raise InvalidOption, "You can't list a group in both with and without." \
        " The offending groups are: #{conflicting_groups.join(", ")}."
    end

    def check_for_options_conflicts
      if (options[:path] || options[:deployment]) && options[:system]
        error_message = String.new
        error_message << "You have specified both --path as well as --system. Please choose only one option.\n" if options[:path]
        error_message << "You have specified both --deployment as well as --system. Please choose only one option.\n" if options[:deployment]
        raise InvalidOption.new(error_message)
      end
    end

    def check_trust_policy
      trust_policy = options["trust-policy"]
      unless CustomBundler.rubygems.security_policies.keys.unshift(nil).include?(trust_policy)
        raise InvalidOption, "RubyGems doesn't know about trust policy '#{trust_policy}'. " \
          "The known policies are: #{CustomBundler.rubygems.security_policies.keys.join(", ")}."
      end
      CustomBundler.settings.set_command_option_if_given :"trust-policy", trust_policy
    end

    def normalize_groups
      check_for_group_conflicts_in_cli_options

      # need to nil them out first to get around validation for backwards compatibility
      CustomBundler.settings.set_command_option :without, nil
      CustomBundler.settings.set_command_option :with,    nil
      CustomBundler.settings.set_command_option :without, options[:without]
      CustomBundler.settings.set_command_option :with,    options[:with]
    end

    def normalize_settings
      CustomBundler.settings.set_command_option :path, nil if options[:system]
      CustomBundler.settings.set_command_option_if_given :path, options[:path]

      if options["standalone"] && CustomBundler.settings[:path].nil? && !options["local"]
        CustomBundler.settings.temporary(path_relative_to_cwd: false) do
          CustomBundler.settings.set_command_option :path, "bundle"
        end
      end

      bin_option = options["binstubs"]
      bin_option = nil if bin_option&.empty?
      CustomBundler.settings.set_command_option :bin, bin_option if options["binstubs"]

      CustomBundler.settings.set_command_option_if_given :shebang, options["shebang"]

      CustomBundler.settings.set_command_option_if_given :jobs, options["jobs"]

      CustomBundler.settings.set_command_option_if_given :no_prune, options["no-prune"]

      CustomBundler.settings.set_command_option_if_given :no_install, options["no-install"]

      CustomBundler.settings.set_command_option_if_given :clean, options["clean"]

      normalize_groups if options[:without] || options[:with]

      options[:force] = options[:redownload]
    end

    def warn_ambiguous_gems
      # TODO: remove this when we drop CustomBundler 1.x support
      Installer.ambiguous_gems.to_a.each do |name, installed_from_uri, *also_found_in_uris|
        CustomBundler.ui.warn "Warning: the gem '#{name}' was found in multiple sources."
        CustomBundler.ui.warn "Installed from: #{installed_from_uri}"
        CustomBundler.ui.warn "Also found in:"
        also_found_in_uris.each {|uri| CustomBundler.ui.warn "  * #{uri}" }
        CustomBundler.ui.warn "You should add a source requirement to restrict this gem to your preferred source."
        CustomBundler.ui.warn "For example:"
        CustomBundler.ui.warn "    gem '#{name}', :source => '#{installed_from_uri}'"
        CustomBundler.ui.warn "Then uninstall the gem '#{name}' (or delete all bundled gems) and then install again."
      end
    end
  end
end
