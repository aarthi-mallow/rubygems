# frozen_string_literal: true

module CustomBundler
  class CLI::Update
    attr_reader :options, :gems
    def initialize(options, gems)
      @options = options
      @gems = gems
    end

    def run
      CustomBundler.ui.level = "warn" if options[:quiet]

      update_bundler = options[:bundler]

      CustomBundler.self_manager.update_bundler_and_restart_with_it_if_needed(update_bundler) if update_bundler

      Plugin.gemfile_install(CustomBundler.default_gemfile) if CustomBundler.feature_flag.plugins?

      sources = Array(options[:source])
      groups  = Array(options[:group]).map(&:to_sym)

      full_update = gems.empty? && sources.empty? && groups.empty? && !options[:ruby] && !update_bundler

      if full_update && !options[:all]
        if CustomBundler.feature_flag.update_requires_all_flag?
          raise InvalidOption, "To update everything, pass the `--all` flag."
        end
        SharedHelpers.major_deprecation 3, "Pass --all to `bundle update` to update everything"
      elsif !full_update && options[:all]
        raise InvalidOption, "Cannot specify --all along with specific options."
      end

      conservative = options[:conservative]

      if full_update
        if conservative
          CustomBundler.definition(conservative: conservative)
        else
          CustomBundler.definition(true)
        end
      else
        unless CustomBundler.default_lockfile.exist?
          raise GemfileLockNotFound, "This Bundle hasn't been installed yet. " \
            "Run `bundle install` to update and install the bundled gems."
        end
        CustomBundler::CLI::Common.ensure_all_gems_in_lockfile!(gems)

        if groups.any?
          deps = CustomBundler.definition.dependencies.select {|d| (d.groups & groups).any? }
          gems.concat(deps.map(&:name))
        end

        CustomBundler.definition(gems: gems, sources: sources, ruby: options[:ruby],
                           conservative: conservative,
                           bundler: update_bundler)
      end

      CustomBundler::CLI::Common.configure_gem_version_promoter(CustomBundler.definition, options)

      CustomBundler::Fetcher.disable_endpoint = options["full-index"]

      opts = options.dup
      opts["update"] = true
      opts["local"] = options[:local]
      opts["force"] = options[:redownload]

      CustomBundler.settings.set_command_option_if_given :jobs, opts["jobs"]

      CustomBundler.definition.validate_runtime!

      if locked_gems = CustomBundler.definition.locked_gems
        previous_locked_info = locked_gems.specs.reduce({}) do |h, s|
          h[s.name] = { spec: s, version: s.version, source: s.source.identifier }
          h
        end
      end

      installer = Installer.install CustomBundler.root, CustomBundler.definition, opts
      CustomBundler.load.cache if CustomBundler.app_cache.exist?

      if CLI::Common.clean_after_install?
        require_relative "clean"
        CustomBundler::CLI::Clean.new(options).run
      end

      if locked_gems
        gems.each do |name|
          locked_info = previous_locked_info[name]
          next unless locked_info

          locked_spec = locked_info[:spec]
          new_spec = CustomBundler.definition.specs[name].first
          unless new_spec
            unless locked_spec.match_platform(CustomBundler.local_platform)
              CustomBundler.ui.warn "CustomBundler attempted to update #{name} but it was not considered because it is for a different platform from the current one"
            end

            next
          end

          locked_source = locked_info[:source]
          new_source = new_spec.source.identifier
          next if locked_source != new_source

          new_version = new_spec.version
          locked_version = locked_info[:version]
          if new_version < locked_version
            CustomBundler.ui.warn "Note: #{name} version regressed from #{locked_version} to #{new_version}"
          elsif new_version == locked_version
            CustomBundler.ui.warn "CustomBundler attempted to update #{name} but its version stayed the same"
          end
        end
      end

      CustomBundler.ui.confirm "Bundle updated!"
      CustomBundler::CLI::Common.output_without_groups_message(:update)
      CustomBundler::CLI::Common.output_post_install_messages installer.post_install_messages

      CustomBundler::CLI::Common.output_fund_metadata_summary
    end
  end
end
