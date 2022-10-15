# frozen_string_literal: true

git_plugin = self

namespace :rpush do
  standard_actions = {
    start: 'Start Rpush',
    stop: 'Stop Rpush',
    status: 'Get Rpush Status'
  }
  standard_actions.each do |command, description|
    desc description
    task command do
      on roles fetch(:rpush_roles) do |role|
        git_plugin.switch_user(role) do
          git_plugin.systemctl_command(command)
        end
      end
    end
  end

  desc 'Restart Rpush'
  task :restart do
    on roles fetch(:rpush_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.quiet_rpush
        git_plugin.process_block do |process|
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          running = nil

          # get running processes
          while (running.nil? || running.positive?) && git_plugin.duration(start_time) < 10
            command_args = if fetch(:rpush_service_unit_user) == :system
                             [:sudo, 'systemd-cgls']
                           else
                             ['systemd-cgls', '--user']
                           end
            # need to pipe through tr -cd... to strip out systemd colors or you
            # get log error messages for non UTF-8 characters.
            command_args.push(
              '-u', "#{git_plugin.rpush_service_unit_name(process: process)}.service",
              '|', 'tr -cd \'\11\12\15\40-\176\''
            )
            status = capture(*command_args, raise_on_non_zero_exit: false)
            status_match = status.match(/\[(?<running>\d+) of (?<total>\d+) busy\]/)
            break unless status_match

            running = status_match[:running]&.to_i

            colors = SSHKit::Color.new($stdout)
            if running.zero?
              info colors.colorize("✔ Process ##{process}: No running workers. Shutting down for restart!", :green)
            else
              info colors.colorize("⧗ Process ##{process}: Waiting for #{running} workers.", :yellow)
              sleep(1)
            end
          end

          git_plugin.systemctl_command(:stop, process: process)
          git_plugin.systemctl_command(:start, process: process)
        end
      end
    end
  end

  desc 'Quiet Rpush (stop fetching new tasks from Redis)'
  task :quiet do
    on roles fetch(:rpush_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.quiet_rpush
      end
    end
  end

  desc 'Install systemd rpush service'
  task :install do
    on roles fetch(:rpush_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.create_systemd_template
        if git_plugin.config_per_process?
          git_plugin.process_block do |process|
            git_plugin.create_systemd_config_symlink(process)
          end
        end
        git_plugin.systemctl_command(:enable)

        if fetch(:rpush_service_unit_user) != :system && fetch(:rpush_enable_lingering)
          execute :loginctl, 'enable-linger', fetch(:rpush_lingering_user)
        end
      end
    end
  end

  desc 'Uninstall systemd rpush service'
  task :uninstall do
    on roles fetch(:rpush_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.systemctl_command(:stop)
        git_plugin.systemctl_command(:disable)
        if git_plugin.config_per_process?
          git_plugin.process_block do |process|
            git_plugin.delete_systemd_config_symlink(process)
          end
        end
        execute :sudo, :rm, '-f', File.join(
          fetch(:service_unit_path, git_plugin.fetch_systemd_unit_path),
          git_plugin.rpush_service_file_name
        )
      end
    end
  end

  desc 'Generate service_locally'
  task :generate_service_locally do
    run_locally do
      File.write('rpush', git_plugin.compiled_template)
    end
  end

  def fetch_systemd_unit_path
    if fetch(:rpush_service_unit_user) == :system
      # if the path is not standard `set :service_unit_path`
      '/etc/systemd/system/'
    else
      home_dir = backend.capture :pwd
      File.join(home_dir, '.config', 'systemd', 'user')
    end
  end

  def compiled_template
    local_template_directory = fetch(:rpush_service_templates_path)
    search_paths = [
      File.join(local_template_directory, "#{fetch(:rpush_service_unit_name)}.service.capistrano.erb"),
      File.join(local_template_directory, 'rpush.service.capistrano.erb'),
      File.expand_path(
        File.join(*%w[.. .. .. generators capistrano rpush systemd templates rpush.service.capistrano.erb]),
        __FILE__
      )
    ]
    template_path = search_paths.detect { |path| File.file?(path) }
    template = File.read(template_path)
    ERB.new(template).result(binding)
  end

  def create_systemd_template
    ctemplate = compiled_template
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    backend.execute :mkdir, '-p', systemd_path if fetch(:rpush_service_unit_user) == :user

    range = if rpush_processes > 1
              1..rpush_processes
            else
              0..0
            end
    range.each do |index|
      temp_file_name = File.join('/tmp', rpush_service_file_name(index))
      systemd_file_name = File.join(systemd_path, rpush_service_file_name(index))
      backend.upload!(StringIO.new(ctemplate), temp_file_name)

      if fetch(:rpush_service_unit_user) == :system
        backend.execute :sudo, :mv, temp_file_name, systemd_file_name
        backend.execute :sudo, :systemctl, 'daemon-reload'
      else
        backend.execute :mv, temp_file_name, systemd_file_name
        backend.execute :systemctl, '--user', 'daemon-reload'
      end
    end
  end

  def create_systemd_config_symlink(process)
    config = fetch(:rpush_config)
    return unless config

    process_config = config[process - 1]
    if process_config.nil?
      backend.error(
        "No configuration for Process ##{process} found. "\
        'Please make sure you have 1 item in :rpush_config for each process.'
      )
      exit 1
    end

    base_path = fetch(:deploy_to)
    config_link_base_path = File.join(base_path, 'shared', 'rpush_systemd')
    config_link_path = File.join(config_link_base_path, rpush_systemd_config_name(process))
    process_config_path = File.join(base_path, 'current', process_config)

    backend.execute :mkdir, '-p', config_link_base_path
    backend.execute :ln, '-sf', process_config_path, config_link_path
  end

  def delete_systemd_config_symlink(process)
    config_link_path = File.join(fetch(:deploy_to), 'shared', 'rpush_systemd', rpush_systemd_config_name(process))
    backend.execute :rm, config_link_path, raise_on_non_zero_exit: false
  end

  def systemctl_command(*args, process: nil)
    execute_array = if fetch(:rpush_service_unit_user) == :system
                      %i[sudo systemctl]
                    else
                      [:systemctl, '--user']
                    end
    if process && rpush_processes > 1
      execute_array.push(*args, rpush_service_unit_name(process: process)).flatten
    else
      execute_array.push(*args, rpush_service_unit_name).flatten
    end
    backend.execute(*execute_array, raise_on_non_zero_exit: false)
  end

  def quiet_rpush
    systemctl_command(:kill, '-s', :TSTP)
  end

  def switch_user(role, &block)
    su_user = rpush_user
    if su_user != role.user
      yield
    else
      backend.as su_user, &block
    end
  end

  def rpush_user
    fetch(:rpush_user, fetch(:run_as))
  end

  def rpush_config
    config = fetch(:rpush_config)
    return unless config

    config = File.join(fetch(:deploy_to), 'shared', 'rpush_systemd', rpush_systemd_config_name) if config_per_process?
    "--config #{config}"
  end

  def rpush_foreground
    '-f' if fetch(:rpush_foreground)
  end

  def rpush_processes
    fetch(rpush_processes, 1)
  end

  def rpush_service_file_name(index = nil)
    return "#{fetch(:rpush_service_unit_name)}.service" if index.to_i.zero?

    "#{fetch(:rpush_service_unit_name)}@#{index}.service"
  end

  def rpush_service_unit_name(process: nil)
    return "#{fetch(:rpush_service_unit_name)}@#{process}" if process && rpush_processes > 1

    fetch(:rpush_service_unit_name)
  end

  # process = 1 | rpush_systemd_1.yaml
  # process = nil | rpush_systemd_%i.yaml
  def rpush_systemd_config_name(process = nil)
    "rpush_systemd_#{process&.to_s || '%i'}.yaml"
  end

  def config_per_process?
    fetch(:rpush_config).is_a?(Array)
  end

  def process_block(&block)
    (1..rpush_processes).each(&block)
  end

  def duration(start_time)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
  end
end
