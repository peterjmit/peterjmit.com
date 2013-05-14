set :application, "peterjmit"
set :domain,      "#{application}.com"
set :deploy_to,   "/var/www/#{domain}"
set :app_path,    "app"

role :web,        domain
role :app,        domain
role :db,         domain, :primary => true

set :repository,  "git@bitbucket.org:peterjmit/peterjmit.com.git"
set :scm,         :git
set :deploy_via,  :remote_cache
set :branch,    "develop"

set :user, "pete"
set :use_sudo, false
set :keep_releases,  3

after "deploy:restart", "deploy:cleanup"
