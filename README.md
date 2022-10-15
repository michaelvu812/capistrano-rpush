[![Gem Version](https://badge.fury.io/rb/capistrano-rpush.svg)](https://badge.fury.io/rb/capistrano-rpush)

# Capistrano::Rpush

[Capistrano::Rpush](https://github.com/juicyparts/capistrano-rpush) adds [Rpush](https://rubygems.org/gems/rpush) tasks to your [Capistrano](https://rubygems.org/gems/capistrano) deployment.

## Capistrano 3

This gem was developed against version 3.9.1. It uses the experimental ```Capistrano::Plugin```.

## Rpush

This gem was developed against version 3.0.0. Additionally it only provides tasks over a subset of available commands:

    $ rpush --help

```
Commands:
  rpush help [COMMAND]  # Describe available commands or one specific command
  rpush init            # Initialize Rpush into the current directory
  rpush push            # Deliver all pending notifications and then exit
  rpush start           # Start Rpush
  rpush status          # Show the internal status of the running Rpush instance.
  rpush stop            # Stop Rpush
  rpush version         # Print Rpush version

Options:
  -c, [--config=CONFIG]
                               # Default: config/initializers/rpush.rb
  -e, [--rails-env=RAILS-ENV]
                               # Default: development
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-rpush'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-rpush

## Usage

```ruby
  # In Rails.root/Capfile

  require 'capistrano/rpush'
  install_plugin Capistrano::Rpush
```
Or, to install the plugin without its hooks:
```ruby
  # In Rails.root/Capfile

  require 'capistrano/rpush'
  install_plugin Capistrano::Rpush, load_hooks: false
```

Now you can use cap -T to list tasks:

```
cap rpush:restart  # Restart rpush
cap rpush:start    # Start rpush
cap rpush:status   # Status rpush
cap rpush:stop     # Stop rpush
```

### Configuration

The following configurable options are available, and listed with their defaults. Override them to suit your project's needs:

```ruby
  set :rpush_pid, -> { File.join(shared_path, 'tmp', 'pids', 'rpush.pid') }
  set :rpush_env, fetch(:rack_env) { fetch(:rails_env) { fetch(:stage) } }
  set :rpush_log, -> { File.join(shared_path, 'log', 'rpush.log') }
  set :rpush_config, -> { File.join(current_path, 'config', 'initializers', 'rpush.rb') }
  set :rpush_timeout, 30
  set :rpush_roles, [:app]
  set :rpush_processes, 1
```

with systemd options. Override them to suit your project's needs:

```ruby
  set :rpush_service_unit_name, -> { "rpush_#{fetch(:application)}_#{fetch(:rpush_env)}" }
  set :rpush_service_unit_user, :system
  set :rpush_enable_lingering, true
  set :rpush_lingering_user, nil
```

with monit options. Override them to suit your project's needs:

```ruby
  set :rpush_service_name, -> { "rpush_#{fetch(:application)}_#{fetch(:rpush_env)}" }
  set :rpush_monit_templates_path, 'config/deploy/templates'
  set :rpush_monit_conf_dir, '/etc/monit/conf.d'
  set :rpush_monit_conf_file, "#{fetch(:rpush_service_name)}.conf"
  set :rpush_monit_use_sudo, true
  set :monit_bin, '/usr/bin/monit'
  set :rpush_monit_default_hooks, false
```

The options assume ```rpush.rb``` is defined in ```linked_files```. They also assume the following directories are listed in ```linked_dirs```:

    tmp/pids log


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/juicyparts/capistrano-rpush. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

