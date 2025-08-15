require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
  config.hosts.clear
  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true

  # Highlight code that enables cache.
  config.cache_store = :memory_store

  # ==========================================
  # INTEGRATIONS GEM HOT RELOADING CONFIGURATION
  # ==========================================
  
  # Add integrations path to autoload paths for hot reloading
  integrations_lib_path = Rails.root.join("..", "integrations", "lib")
  if File.directory?(integrations_lib_path)
    config.autoload_paths << integrations_lib_path.to_s
    config.autoload_once_paths << integrations_lib_path.to_s
  end

  # Set up file watcher for integrations directory
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Configure reloader to watch integrations directory
  Rails.application.reloader.to_prepare do
    begin
      integrations_path = Rails.root.join("..", "integrations", "lib")
      
      if File.directory?(integrations_path) && defined?(Outhad::Integrations)
        # Only attempt reloading if we're in a request context, not during initialization
        if Rails.application.initialized?
          Rails.logger&.debug "🔄 Preparing to reload integrations gem..."
          
          # Clear autoloaded constants that are safe to remove
          integration_constants = []
          begin
            Outhad::Integrations.constants.each do |const_name|
              begin
                constant = Outhad::Integrations.const_get(const_name)
                # Only remove module constants that are safe to reload
                if constant.is_a?(Module) && const_name.to_s.match?(/^(Source|Destination|Core)$/)
                  integration_constants << const_name
                end
              rescue NameError
                # Skip constants that are not accessible
                next
              end
            end

            # Remove only safe constants
            integration_constants.each do |const_name|
              begin
                if Outhad::Integrations.const_defined?(const_name)
                  Outhad::Integrations.send(:remove_const, const_name)
                  Rails.logger&.debug "Removed constant: #{const_name}"
                end
              rescue => e
                Rails.logger&.debug "Could not remove constant #{const_name}: #{e.message}"
              end
            end
          rescue => e
            Rails.logger&.debug "Error during constant enumeration: #{e.message}"
          end
        end
      end
    rescue => e
      Rails.logger&.error "Error in integrations reloader: #{e.message}"
    end
  end

  # Add integrations directory to watchable files
  config.watchable_files.concat Dir[Rails.root.join("..", "integrations", "lib", "**", "*.rb")]

  # Log after Rails is fully initialized
  config.after_initialize do
    Rails.logger.info "🔥 Integrations hot reloading enabled - integrations gem will reload on file changes"
  end
end
