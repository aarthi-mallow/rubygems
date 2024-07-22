# frozen_string_literal: true

module CustomBundler
  class CLI::Binstubs
    attr_reader :options, :gems
    def initialize(options, gems)
      @options = options
      @gems = gems
    end

    def run
      CustomBundler.definition.validate_runtime!
      path_option = options["path"]
      path_option = nil if path_option&.empty?
      CustomBundler.settings.set_command_option :bin, path_option if options["path"]
      CustomBundler.settings.set_command_option_if_given :shebang, options["shebang"]
      installer = Installer.new(CustomBundler.root, CustomBundler.definition)

      installer_opts = {
        force: options[:force],
        binstubs_cmd: true,
        all_platforms: options["all-platforms"],
      }

      if options[:all]
        raise InvalidOption, "Cannot specify --all with specific gems" unless gems.empty?
        @gems = CustomBundler.definition.specs.map(&:name)
        installer_opts.delete(:binstubs_cmd)
      elsif gems.empty?
        CustomBundler.ui.error "`bundle binstubs` needs at least one gem to run."
        exit 1
      end

      gems.each do |gem_name|
        spec = CustomBundler.definition.specs.find {|s| s.name == gem_name }
        unless spec
          raise GemNotFound, CustomBundler::CLI::Common.gem_not_found_message(
            gem_name, CustomBundler.definition.specs
          )
        end

        if options[:standalone]
          if gem_name == "bundler"
            CustomBundler.ui.warn("Sorry, CustomBundler can only be run via RubyGems.") unless options[:all]
            next
          end

          CustomBundler.settings.temporary(path: CustomBundler.settings[:path] || CustomBundler.root) do
            installer.generate_standalone_bundler_executable_stubs(spec, installer_opts)
          end
        else
          installer.generate_bundler_executable_stubs(spec, installer_opts)
        end
      end
    end
  end
end
