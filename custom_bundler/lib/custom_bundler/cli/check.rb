# frozen_string_literal: true

module CustomBundler
  class CLI::Check
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      CustomBundler.settings.set_command_option_if_given :path, options[:path]

      definition = CustomBundler.definition
      definition.validate_runtime!

      begin
        definition.resolve_only_locally!
        not_installed = definition.missing_specs
      rescue GemNotFound, SolveFailure
        CustomBundler.ui.error "CustomBundler can't satisfy your Gemfile's dependencies."
        CustomBundler.ui.warn "Install missing gems with `bundle install`."
        exit 1
      end

      if not_installed.any?
        CustomBundler.ui.error "The following gems are missing"
        not_installed.each {|s| CustomBundler.ui.error " * #{s.name} (#{s.version})" }
        CustomBundler.ui.warn "Install missing gems with `bundle install`"
        exit 1
      elsif !CustomBundler.default_lockfile.file? && CustomBundler.frozen_bundle?
        CustomBundler.ui.error "This bundle has been frozen, but there is no #{SharedHelpers.relative_lockfile_path} present"
        exit 1
      else
        CustomBundler.load.lock(preserve_unknown_sections: true) unless options[:"dry-run"]
        CustomBundler.ui.info "The Gemfile's dependencies are satisfied"
      end
    end
  end
end
