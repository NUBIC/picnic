require 'optparse'

module Picnic
  class Cli
    attr_accessor :app, :options
    
    def initialize(app, options = {})
      @app = app
      
      @options = {}
      @options[:app_path]  ||= File.expand_path(File.dirname(File.expand_path(__FILE__))+"/../lib/#{app}.rb")
      @options[:pid_file]  ||= "/etc/#{app}/#{app}.pid"
      @options[:conf_file] ||= nil
      @options[:verbose]   ||= false
      
      @options = options
    end
    
    def handle_cli_input
      if File.exists? options[:app_path]
        # try to use given app base path
        $: << File.dirname(options[:app_path])
        path = File.dirname(options[:app_path])+"/"
      else
        # fall back to using gem installation
        path = ""
        require 'rubygems'
        gem(app)
      end
      
      $PID_FILE = "/etc/#{app}/#{app}.pid" 
      
      OptionParser.new do |opts|
        opts.banner = "Usage: #{app} [options]"
      
        opts.on("-c", "--config FILE", "Use config file (default is /etc/#{app}/config.yml)") do |c|
          puts "Using config file #{c}"
          $CONFIG_FILE = c
        end
        
        opts.on("-d", "--daemonize", "Run as a daemon (only when using webrick or mongrel)") do |c|
          $DAEMONIZE = true
        end
      
        opts.on("-P", "--pid_file FILE", "Use pid file (default is /etc/#{app}/#{app}.pid)") do |c|
          if $DAEMONIZE && !File.exists?(c)
            puts "Using pid file '#{c}'"
            $PID_FILE = c
          elsif File.exists?(c)
            puts "The pid file already exists.  Is #{app} running?\n" +
              "You will have to first manually remove the pid file at '#{c}' to start the server as a daemon."
            exit 1
          else
            puts "Not running as daemon.  Ignoring pid option"
          end
        end
      
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        
        opts.on_tail("-v", "--version", "Show version number") do
          require "#{path}#{app}/version"
          puts "#{app}-#{VERSION::STRING}"
          exit
        end
      end.parse!
      
      $APP_PATH = options[:app_path]
      
      load "#{path}/lib/#{app}.rb"
    end
  end
end


