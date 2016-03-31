require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'spree/testing_support/extension_rake'

RSpec::Core::RakeTask.new(:spec)

Bundler::GemHelper.install_tasks

task default: :spec

desc "Generates a dummy app for testing"
task :test_app do
  ENV['LIB_NAME'] = 'spree_product_assembly'
  Rake::Task['extension:test_app'].invoke
end
