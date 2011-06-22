set :application, "cropper.redpeppix.com"
role :app, application
role :web, application
role :db,  application, :primary => true

set :user, "deploy"
set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:redpeppix-gmbh-co-kg/redpeppix.-cropper.git"
set :branch, "master"

namespace :deploy do
  desc "Tell Passenger to restart the app."
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    #run "ln -nfs #{shared_path}/config/exceptional.yml #{release_path}/config/exceptional.yml"
    #run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
    #run "ln -nfs #{shared_path}/credits #{release_path}/public/credits"
    #run "ln -nfs #{shared_path}/invoices #{release_path}/public/invoices"
    #run "ln -nfs #{shared_path}/logos #{release_path}/public/logos"
    #run "ln -nfs #{shared_path}/heatmaps #{release_path}/public/images/heatmaps"
  end
  
  desc "Sync the public/assets directory."
  task :assets do
    system "rsync -vr --exclude='.DS_Store' public/assets #{user}@#{application}:#{shared_path}/"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'

# taken and adapted from bundler
namespace :bundle do
  task :install do
    run "bundle install --gemfile #{release_path}/Gemfile --path #{fetch(:bundle_dir, "#{shared_path}/bundle")} --deployment --without development test cucumber"
  end
end

after "deploy:update_code", "bundle:install"