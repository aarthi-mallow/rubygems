# frozen_string_literal: true

module CustomBundler
  class CLI::Show
    attr_reader :options, :gem_name, :latest_specs
    def initialize(options, gem_name)
      @options = options
      @gem_name = gem_name
      @verbose = options[:verbose] || options[:outdated]
      @latest_specs = fetch_latest_specs if @verbose
    end

    def run
      CustomBundler.ui.silence do
        CustomBundler.definition.validate_runtime!
        CustomBundler.load.lock
      end

      if gem_name
        if gem_name == "bundler"
          path = File.expand_path("../../..", __dir__)
        else
          spec = CustomBundler::CLI::Common.select_spec(gem_name, :regex_match)
          return unless spec
          path = spec.full_gem_path
          unless File.directory?(path)
            return CustomBundler.ui.warn "The gem #{gem_name} has been deleted. It was installed at: #{path}"
          end
        end
        return CustomBundler.ui.info(path)
      end

      if options[:paths]
        CustomBundler.load.specs.sort_by(&:name).map do |s|
          CustomBundler.ui.info s.full_gem_path
        end
      else
        CustomBundler.ui.info "Gems included by the bundle:"
        CustomBundler.load.specs.sort_by(&:name).each do |s|
          desc = "  * #{s.name} (#{s.version}#{s.git_version})"
          if @verbose
            latest = latest_specs.find {|l| l.name == s.name }
            CustomBundler.ui.info <<~END
              #{desc.lstrip}
              \tSummary:  #{s.summary || "No description available."}
              \tHomepage: #{s.homepage || "No website available."}
              \tStatus:   #{outdated?(s, latest) ? "Outdated - #{s.version} < #{latest.version}" : "Up to date"}
            END
          else
            CustomBundler.ui.info desc
          end
        end
      end
    end

    private

    def fetch_latest_specs
      definition = CustomBundler.definition(true)
      if options[:outdated]
        CustomBundler.ui.info "Fetching remote specs for outdated check...\n\n"
        CustomBundler.ui.silence { definition.resolve_remotely! }
      else
        definition.resolve_with_cache!
      end
      CustomBundler.reset!
      definition.specs
    end

    def outdated?(current, latest)
      return false unless latest
      Gem::Version.new(current.version) < Gem::Version.new(latest.version)
    end
  end
end
