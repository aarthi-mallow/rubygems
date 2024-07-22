# frozen_string_literal: true

module CustomBundler
  class CLI::Fund
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      CustomBundler.definition.validate_runtime!

      groups = Array(options[:group]).map(&:to_sym)

      deps = if groups.any?
        CustomBundler.definition.dependencies_for(groups)
      else
        CustomBundler.definition.requested_dependencies
      end

      fund_info = deps.each_with_object([]) do |dep, arr|
        spec = CustomBundler.definition.specs[dep.name].first
        if spec.metadata.key?("funding_uri")
          arr << "* #{spec.name} (#{spec.version})\n  Funding: #{spec.metadata["funding_uri"]}"
        end
      end

      if fund_info.empty?
        CustomBundler.ui.info "None of the installed gems you directly depend on are looking for funding."
      else
        CustomBundler.ui.info fund_info.join("\n")
      end
    end
  end
end
