# frozen_string_literal: true

module CustomBundler
  class CLI::Init
    attr_reader :options
    def initialize(options)
      @options = options
    end

    def run
      if File.exist?(gemfile)
        CustomBundler.ui.error "#{gemfile} already exists at #{File.expand_path(gemfile)}"
        exit 1
      end

      unless File.writable?(Dir.pwd)
        CustomBundler.ui.error "Can not create #{gemfile} as the current directory is not writable."
        exit 1
      end

      if options[:gemspec]
        gemspec = File.expand_path(options[:gemspec])
        unless File.exist?(gemspec)
          CustomBundler.ui.error "Gem specification #{gemspec} doesn't exist"
          exit 1
        end

        spec = CustomBundler.load_gemspec_uncached(gemspec)

        File.open(gemfile, "wb") do |file|
          file << "# Generated from #{gemspec}\n"
          file << spec.to_gemfile
        end
      else
        File.open(File.expand_path("../templates/Gemfile", __dir__), "r") do |template|
          File.open(gemfile, "wb") do |destination|
            IO.copy_stream(template, destination)
          end
        end
      end

      puts "Writing new #{gemfile} to #{SharedHelpers.pwd}/#{gemfile}"
    end

    private

    def gemfile
      @gemfile ||= options[:gemfile] || CustomBundler.preferred_gemfile_name
    end
  end
end
