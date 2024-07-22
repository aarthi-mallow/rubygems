# frozen_string_literal: true

require_relative "shared_helpers"

if CustomBundler::SharedHelpers.in_bundle?
  require_relative "../custom_bundler"

  # autoswitch to locked CustomBundler version if available
  CustomBundler.auto_switch

  # try to auto_install first before we get to the `CustomBundler.ui.silence`, so user knows what is happening
  CustomBundler.auto_install

  if STDOUT.tty? || ENV["BUNDLER_FORCE_TTY"]
    begin
      CustomBundler.ui.silence { CustomBundler.setup }
    rescue CustomBundler::BundlerError => e
      CustomBundler.ui.error e.message
      CustomBundler.ui.warn e.backtrace.join("\n") if ENV["DEBUG"]
      if e.is_a?(CustomBundler::GemNotFound)
        default_bundle = Gem.bin_path("bundler", "bundle")
        current_bundle = CustomBundler::SharedHelpers.bundle_bin_path
        suggested_bundle = default_bundle == current_bundle ? "bundle" : current_bundle
        suggested_cmd = "#{suggested_bundle} install"
        original_gemfile = CustomBundler.original_env["BUNDLE_GEMFILE"]
        suggested_cmd += " --gemfile #{original_gemfile}" if original_gemfile
        CustomBundler.ui.warn "Run `#{suggested_cmd}` to install missing gems."
      end
      exit e.status_code
    end
  else
    CustomBundler.ui.silence { CustomBundler.setup }
  end

  # We might be in the middle of shelling out to rubygems
  # (RUBYOPT=-rbundler/setup), so we need to give rubygems the opportunity of
  # not being silent.
  Gem::DefaultUserInteraction.ui = nil
end
