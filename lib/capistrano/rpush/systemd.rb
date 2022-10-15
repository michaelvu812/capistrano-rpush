# frozen_string_literal: true

module Capistrano
  class Rpush::Systemd < Capistrano::Plugin
    include Rpush::Helpers

    def set_defaults
      set_if_empty :rpush_service_unit_name, 'rpush'
      set_if_empty :rpush_service_unit_user, :user # :system
      set_if_empty :rpush_enable_lingering, true
      set_if_empty :rpush_lingering_user, nil
      set_if_empty :rpush_service_templates_path, 'config/deploy/templates'
    end

    def define_tasks
      eval_rakefile File.expand_path('../tasks/systemd.rake', __dir__)
    end
  end
end
