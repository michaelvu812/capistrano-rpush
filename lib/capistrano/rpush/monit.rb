# frozen_string_literal: true

module Capistrano
  class Rpush::Monit < Capistrano::Plugin
    include Rpush::Helpers

    def set_defaults
      set_if_empty :monit_bin, '/usr/bin/monit'
      set_if_empty :rpush_monit_conf_dir, '/etc/monit/conf.d'
      set_if_empty :rpush_monit_conf_file, -> { "#{rpush_service_name}.conf" }
      set_if_empty :rpush_monit_use_sudo, true
      set_if_empty :rpush_monit_default_hooks, true
      set_if_empty :rpush_monit_templates_path, 'config/deploy/templates'
      set_if_empty :rpush_monit_group, nil
    end

    def define_tasks
      eval_rakefile File.expand_path('../tasks/monit.rake', __dir__)
    end
  end
end
