# frozen_string_literal: true

git_plugin = self

namespace :deploy do
  before :starting, :check_rpush_monit_hooks do
    invoke 'rpush:monit:add_default_hooks' if fetch(:rpush_default_hooks) && fetch(:rpush_monit_default_hooks)
  end
end

namespace :rpush do
  namespace :monit do
    task :add_default_hooks do
      before 'deploy:updating',  'rpush:monit:unmonitor'
      after  'deploy:published', 'rpush:monit:monitor'
    end

    desc 'Config rpush monit-service'
    task :config do
      on roles(fetch(:rpush_roles)) do |role|
        @role = role
        git_plugin.upload_rpush_template 'rpush_monit', "#{fetch(:tmp_dir)}/monit.conf", @role

        git_plugin.switch_user(role) do
          mv_command = "mv #{fetch(:tmp_dir)}/monit.conf #{fetch(:rpush_monit_conf_dir)}/#{fetch(:rpush_monit_conf_file)}"

          git_plugin.sudo_if_needed mv_command
          git_plugin.sudo_if_needed "#{fetch(:monit_bin)} reload"
        end
      end
    end

    desc 'Monitor rpush monit-service'
    task :monitor do
      on roles(fetch(:rpush_roles)) do |role|
        git_plugin.switch_user(role) do
          git_plugin.sudo_if_needed "#{fetch(:monit_bin)} monitor #{git_plugin.rpush_service_name}"
        rescue StandardError
          invoke 'rpush:monit:config'
          git_plugin.sudo_if_needed "#{fetch(:monit_bin)} monitor #{git_plugin.rpush_service_name}"
        end
      end
    end

    desc 'Unmonitor rpush monit-service'
    task :unmonitor do
      on roles(fetch(:rpush_roles)) do |role|
        git_plugin.switch_user(role) do
          git_plugin.sudo_if_needed "#{fetch(:monit_bin)} unmonitor #{git_plugin.rpush_service_name}"
        rescue StandardError
          # no worries here
        end
      end
    end
  end

  desc 'Start rpush monit-service'
  task :start do
    on roles(fetch(:rpush_roles)) do |role|
      git_plugin.switch_user(role) do
        git_plugin.sudo_if_needed "#{fetch(:monit_bin)} start #{git_plugin.rpush_service_name}"
      end
    end
  end

  desc 'Stop rpush monit-service'
  task :stop do
    on roles(fetch(:rpush_roles)) do |role|
      git_plugin.switch_user(role) do
        git_plugin.sudo_if_needed "#{fetch(:monit_bin)} stop #{git_plugin.rpush_service_name}"
      end
    end
  end

  desc 'Restart rpush monit-service'
  task :restart do
    on roles(fetch(:rpush_roles)) do |_role|
      git_plugin.sudo_if_needed "#{fetch(:monit_bin)} restart #{git_plugin.rpush_service_name}"
    end
  end

  def rpush_service_name
    fetch(:rpush_service_name, "rpush_#{fetch(:application)}_#{fetch(:rpush_env)}")
  end

  def sudo_if_needed(command)
    if use_sudo?
      backend.execute :sudo, command
    else
      backend.execute command
    end
  end

  def use_sudo?
    fetch(:rpush_monit_use_sudo)
  end

  def upload_rpush_template(from, to, role)
    template = rpush_template(from, role)
    backend.upload!(StringIO.new(ERB.new(template).result(binding)), to)
  end

  def rpush_template(name, role)
    local_template_directory = fetch(:rpush_monit_templates_path)

    search_paths = [
      "#{name}-#{role.hostname}-#{fetch(:stage)}.erb",
      "#{name}-#{role.hostname}.erb",
      "#{name}-#{fetch(:stage)}.erb",
      "#{name}.erb"
    ].map { |filename| File.join(local_template_directory, filename) }

    global_search_path = File.expand_path(
      File.join(*%w[.. .. .. generators capistrano rpush monit templates], "#{name}.conf.erb"),
      __FILE__
    )

    search_paths << global_search_path

    template_path = search_paths.detect { |path| File.file?(path) }
    File.read(template_path)
  end
end
