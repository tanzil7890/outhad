# Integrations Hot Reloading Initializer
# This ensures the outhad-integrations gem reloads properly during development

if Rails.env.development?
  Rails.application.configure do
    # Enhanced integration reloading with better error handling
    config.to_prepare do
      begin
        integrations_path = Rails.root.join("..", "integrations", "lib")
        
        # Only proceed if Rails is fully initialized to avoid startup errors
        if File.directory?(integrations_path) && Rails.application.initialized? && defined?(Outhad::Integrations)
          Rails.logger&.debug "🔄 Reloading integrations gem constants..."
          
          # Clear cached connector classes safely
          if defined?(Outhad::Integrations::Service)
            begin
              Outhad::Integrations::Service.class_eval do
                # Clear any instance variables that might cache connector classes
                instance_variables.each do |var|
                  remove_instance_variable(var) if var.to_s.include?('connector')
                end
              end
            rescue => e
              Rails.logger&.debug "Could not clear Service instance variables: #{e.message}"
            end
          end
          
          Rails.logger&.debug "✅ Integrations gem prepared for hot reloading"
        end
        
      rescue => e
        Rails.logger&.error "❌ Error in integrations hot reload initializer: #{e.message}" if Rails.logger
        # Don't re-raise to avoid breaking Rails startup
      end
    end
    
    # Add file change notification
    config.after_initialize do
      if defined?(Listen) && File.directory?(Rails.root.join("..", "integrations"))
        Rails.logger.info "🎯 Setting up file watcher for integrations directory..."
        
        listener = Listen.to(Rails.root.join("..", "integrations", "lib")) do |modified, added, removed|
          if (modified + added + removed).any? { |file| file.end_with?('.rb') }
            Rails.logger.info "🔄 Integrations file changed, triggering reload..."
            
            # Touch a file to trigger Rails reloader
            FileUtils.touch(Rails.root.join("tmp", "restart.txt"))
          end
        end
        
        listener.start
        Rails.logger.info "👂 File watcher started for integrations hot reloading"
      end
    end
  end
  
  # Monkey patch for better error handling during integration loading
  module IntegrationsReloadPatch
    def connector_class(connector_type, connector_name)
      begin
        super
      rescue NameError => e
        Rails.logger.warn "🔄 Connector class not found, attempting reload: #{e.message}"
        
        # Force reload and try again
        integrations_path = Rails.root.join("..", "integrations", "lib")
        load File.join(integrations_path, "outhad", "integrations", "service.rb")
        
        super
      end
    end
  end
  
  # Apply the patch after service is loaded
  Rails.application.config.after_initialize do
    if defined?(Outhad::Integrations::Service)
      Outhad::Integrations::Service.prepend(IntegrationsReloadPatch)
      Rails.logger.info "🩹 Applied integrations reload patch"
    end
  end
  
  Rails.logger.info "🚀 Integrations hot reloading initializer loaded"
end