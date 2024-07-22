# frozen_string_literal: true

require_relative "shared_helpers"
CustomBundler::SharedHelpers.major_deprecation 2,
  "The CustomBundler task for Vlad"

# Vlad task for CustomBundler.
#
# Add "require 'bundler/vlad'" in your Vlad deploy.rb, and
# include the vlad:bundle:install task in your vlad:deploy task.
require_relative "deployment"

include Rake::DSL if defined? Rake::DSL

namespace :vlad do
  CustomBundler::Deployment.define_task(Rake::RemoteTask, :remote_task, roles: :app)
end
