# frozen_string_literal: true

require "rbconfig"

module CustomBundler
  class CLI::Issue
    def run
      CustomBundler.ui.info <<~EOS
        Did you find an issue with CustomBundler? Before filing a new issue,
        be sure to check out these resources:

        1. Check out our troubleshooting guide for quick fixes to common issues:
        https://github.com/rubygems/rubygems/blob/master/bundler/doc/TROUBLESHOOTING.md

        2. Instructions for common CustomBundler uses can be found on the documentation
        site: https://bundler.io/

        3. Information about each CustomBundler command can be found in the CustomBundler
        man pages: https://bundler.io/man/bundle.1.html

        Hopefully the troubleshooting steps above resolved your problem!  If things
        still aren't working the way you expect them to, please let us know so
        that we can diagnose and help fix the problem you're having, by filling
        in the new issue form located at
        https://github.com/rubygems/rubygems/issues/new?labels=CustomBundler&template=bundler-related-issue.md,
        and copy and pasting the information below.

      EOS

      CustomBundler.ui.info CustomBundler::Env.report

      CustomBundler.ui.info "\n## Bundle Doctor"
      doctor
    end

    def doctor
      require_relative "doctor"
      CustomBundler::CLI::Doctor.new({}).run
    end
  end
end
