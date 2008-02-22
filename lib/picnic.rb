$: << File.dirname(File.expand_path(__FILE__))
$: << File.dirname(File.expand_path(__FILE__))+"/../vendor/camping-1.5.180/lib"

require 'camping'

require 'active_support' unless Object.const_defined?(:ActiveSupport)

require 'picnic/utils'
require 'picnic/conf'
require 'picnic/postambles'
require 'picnic/controllers'


class Module
  
  # Adds Picnic functionality to a Camping-enabled module.
  #
  # Example:
  #
  #   Camping.goes :Blog
  #   Blog.picnic!
  #
  # Your <tt>Blog</tt> Camping app now has Picnic functionality.
  def picnic!
    include Picnic
    
    puts "Adding Picnic functionality to #{self} from #{File.dirname(File.expand_path(__FILE__))}..."
    self.module_eval do
      # Initialize your application's logger. 
      # This is automatically done for you when you call #picnic!
      # The logger is initialized based on your <tt>:log</tt> configuration.
      # See <tt>config.example.yml</tt> for info on configuring the logger.
      def init_logger
        puts "Initializing #{self} logger..."
        $LOG = self::Utils::Logger.new(self::Conf.log[:file])
        $LOG.level = "#{self}::Utils::Logger::#{self::Conf.log[:level]}".constantize
      end
      module_function :init_logger
      
      # Initialize your application's database logger. 
      # If enabled, all SQL queries going through ActiveRecord will be logged here.
      def init_db_logger
        begin
          if self::Conf.db_log
            log_file = self::Conf.db_log[:file] || "#{self.to_s.downcase}_db.log"
            self::Models::Base.logger = Logger.new(log_file)
            self::Models::Base.logger.level = "#{self}::Utils::Logger::#{self::Conf.db_log[:level] || 'DEBUG'}".constantize
          end
        rescue Errno::EACCES => e
          $LOG.warn "Can't write to database log file at '#{log_file}': #{e}"
        end
      end
      module_function :init_db_logger
      
      # Enable authentication for your app.
      #
      # For example:
      #
      #   Camping.goes :Blog
      #   Blog.picnic!
      #
      #   $CONF[:authentication] ||= {:username => 'admin', :password => 'picnic'}
      #   Blog.authenticate_using :basic
      #
      #   module Blog
      #     def self.authenticate(credentials)
      #       credentials[:username] == Taskr::Conf[:authentication][:username] &&
      #         credentials[:password] == Taskr::Conf[:authentication][:password]
      #     end
      #   end
      #
      # Note that in the above example we use the authentication configuration from
      # your app's conf file.
      #
      def authenticate_using(mod)
        require 'picnic/authentication'
        mod = "#{self}::Authentication::#{mod.to_s.camelize}".constantize unless mod.kind_of? Module
        
        $LOG.info("Enabling authentication for all requests using #{mod.inspect}.")
        
        module_eval do
          include mod
        end
      end
      module_function :authenticate_using
    
      # Launches the web server to run your Picnic app.
      # This method will continue to run as long as your server is running.
      def start_picnic
          require 'picnic/postambles'
          self.extend self::Postambles
          
          if $PID_FILE && !(self::Conf.server.to_s == 'mongrel' || self::Conf.server.to_s == 'webrick')
            $LOG.warn("Unable to create a pid file. You must use mongrel or webrick for this feature.")
          end
          
          puts "\nStarting with configuration: #{$CONF.to_yaml}"
          puts
        
        #  begin
            raise NoMethodError if self::Conf.server.nil?
            send(self::Conf.server)
        #  rescue NoMethodError => e
        #    # FIXME: this rescue can sometime report the incorrect error messages due to other underlying problems
        #    #         raising a NoMethodError
        #    if Fluxr::Conf.server
        #      raise e, "The server setting '#{Fluxr::Conf.server}' in your config.yml file is invalid."
        #    else
        #      raise e, "You must have a 'server' setting in your config.yml file. Please see the Fluxr documentation."
        #    end
        #  end
      end
      module_function :start_picnic
      
      c = File.dirname(File.expand_path(__FILE__))+'/picnic/controllers.rb'
      p = IO.read(c).gsub("Picnic", self.to_s)
      eval p, TOPLEVEL_BINDING
      
    end
    
    self::Conf.load(self)
    init_logger
  end
end