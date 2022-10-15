# frozen_string_literal: true

require 'capistrano/bundler'
require 'capistrano/plugin'

module Capistrano
  class Rpush < Capistrano::Plugin
    def define_tasks
      eval_rakefile File.expand_path('tasks/rpush.rake', __dir__)
    end

    def set_defaults
      set_if_empty :rpush_default_hooks, true
      set_if_empty :rpush_roles,         fetch(:rpush_role, :app)
      set_if_empty :rpush_env,           -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
      set_if_empty :rpush_conf,          -> { File.join(current_path, 'config', 'initializers', 'rpush.rb') }
      set_if_empty :rpush_log,           -> { File.join(shared_path, 'log', 'rpush.log') }
      set_if_empty :rpush_error_log,     -> { File.join(shared_path, 'log', 'rpush.error.log') }
      set_if_empty :rpush_pid,           -> { File.join(shared_path, 'tmp', 'pids', 'rpush.pid') }

      append :chruby_map_bins, 'rpush'
      append :rbenv_map_bins, 'rpush'
      append :rvm_map_bins, 'rpush'
      append :bundle_bins, 'rpush'
    end

  end

end

require_relative 'rpush/helpers'
require_relative 'rpush/systemd'
require_relative 'rpush/monit'
