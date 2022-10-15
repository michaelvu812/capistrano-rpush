# frozen_string_literal: true

module Capistrano
  module Rpush::Helpers
    def rpush_config
      "--config #{fetch(:rpush_config)}" if fetch(:rpush_config)
    end

    def rpush_logfile
      fetch(:rpush_log)
    end

    def rpush_foreground
      '-f' if fetch(:rpush_foreground)
    end

    def switch_user(role, &block)
      su_user = rpush_user(role)
      if su_user == role.user
        yield
      else
        as su_user, &block
      end
    end

    def rpush_user(role = nil)
      if role.nil?
        fetch(:rpush_user)
      else
        properties = role.properties
        properties.fetch(:rpush_user) || # local property for rpush only
          fetch(:rpush_user) ||
          properties.fetch(:run_as) || # global property across multiple capistrano gems
          role.user
      end
    end

    def expanded_bundle_path
      backend.capture(:echo, SSHKit.config.command_map[:bundle]).strip
    end
  end
end
