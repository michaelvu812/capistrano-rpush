# frozen_string_literal: true

namespace :deploy do
  before :starting, :check_rpush_hooks do
    invoke 'rpush:add_default_hooks' if fetch(:rpush_default_hooks)
  end
end

namespace :rpush do
  task :add_default_hooks do
    after 'deploy:starting', 'rpush:quiet' if Rake::Task.task_defined?('rpush:quiet')
    after 'deploy:updated', 'rpush:stop'
    after 'deploy:published', 'rpush:start'
    after 'deploy:failed', 'rpush:restart'
  end
end
