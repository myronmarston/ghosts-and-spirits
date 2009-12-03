namespace :gs do
  desc "Export the static data to db/static_data.yml"
  task :export_static_data do
    require "#{File.expand_path(File.dirname(__FILE__) + '/../../')}/vendor/extensions/import_export/lib/loader.rb"
    Loader.class_eval do
      def core_models_from_database
        original_models_from_database - [Radiant::Config, Comment, Rating, User]
      end
      alias :original_models_from_database :models_from_database
      alias :models_from_database :core_models_from_database
    end

    ENV['TEMPLATE'] = 'db/static_data.yml'
    Rake::Task['db:export'].invoke
  end

  desc "Bootstrap your database for ghostsandspirits.net."
  task :bootstrap do
    require 'highline/import'
    if agree("Are you sure you want to bootstrap the database?  You will lose all of your current data. [yn]")
      %w(db:drop db:create db:migrate db:migrate:extensions).each { |t| Rake::Task[t].invoke }

      # Some of the extension migrations create data we don't want...
      [Page, PagePart, Snippet, Layout].each(&:delete_all)

      require 'radiant/setup'
      require File.join(Rails.root, 'vendor', 'extensions', 'import_export', 'lib', 'radiant_setup_create_records_patch')

      Radiant::Setup.bootstrap(
        :admin_name => ENV['ADMIN_NAME'],
        :admin_username => ENV['ADMIN_USERNAME'],
        :admin_password => ENV['ADMIN_PASSWORD'],
        :database_template => 'db/static_data.yml'
      )
      Page.update_all({ :average_rating => 0, :comments_count => 0 })
      Rake::Task['gs:import:all'].invoke
    end
  end
end