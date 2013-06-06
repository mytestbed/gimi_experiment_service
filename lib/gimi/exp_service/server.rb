require 'rubygems'
require 'rack'
require 'rack/showexceptions'
require 'thin'
require 'data_mapper'
require 'omf_common/lobject'
require 'omf_common/load_yaml'

require 'omf-sfa/am/am_runner'
#require 'omf-sfa/am/am_manager'
#require 'omf-sfa/am/am_scheduler'

require 'omf_common/lobject'

module GIMI::ExperimentService

  class Server
    # Don't use LObject as we haveb't initialized the logging system yet. Happens in 'init_logger'
    include OMF::Common::Loggable
    extend OMF::Common::Loggable

    def init_logger
      OMF::Common::Loggable.init_log 'server', :searchPath => File.join(File.dirname(__FILE__), 'server')

      @config = OMF::Common::YAML.load('config', :path => [File.dirname(__FILE__) + '/../../../etc/gimi-exp-service'])[:gimi_exp_service]
    end

    def init_data_mapper(options)
      #@logger = OMF::Common::Loggable::_logger('am_server')
      #OMF::Common::Loggable.debug "options: #{options}"
      debug "options: #{options}"

      # Configure the data store
      #
      DataMapper::Logger.new(options[:dm_log] || $stdout, :info)
      #DataMapper::Logger.new($stdout, :info)

      #DataMapper.setup(:default, config[:data_mapper] || {:adapter => 'yaml', :path => '/tmp/am_test2'})
      DataMapper.setup(:default, options[:dm_db])

      require 'omf-sfa/resource'
      require 'gimi/resource'
      DataMapper::Model.raise_on_save_failure = true
      DataMapper.finalize

      # require  'dm-migrations'
      # DataMapper.auto_migrate!

      DataMapper.auto_upgrade! if options[:dm_auto_upgrade]
    end


    def load_test_state(options)
      require  'dm-migrations'
      DataMapper.auto_migrate!

      require 'omf-sfa/resource/oaccount'
      #account = am.find_or_create_account(:name => 'foo')
      account = OMF::SFA::Resource::OAccount.create(:name => 'foo')
      require 'omf-sfa/resource/project'
      pA = OMF::SFA::Resource::Project.create(:name => 'projectA')
      pB = OMF::SFA::Resource::Project.create(:name => 'projectB')

      require 'gimi/resource/experiment'
      e1 = GIMI::Resource::Experiment.create(:name => 'exp1', :project => pA)
      e1.iticket = GIMI::Resource::ITicket.create()
      e1.save

      require 'omf-sfa/resource/user'
      u1 = OMF::SFA::Resource::User.create(:name => 'user1')
      u2 = OMF::SFA::Resource::User.create(:name => 'user2')


      u1.projects << pA
      u1.projects << pB
      u1.save

      u2.projects << pB
      u2.save
    end

    def run(opts)
      opts[:handlers] = {
        # Should be done in a better way
        :pre_rackup => lambda {
        },
        :pre_parse => lambda do |p, options|
          p.on("--test-load-state", "Load an initial state for testing") do |n| options[:load_test_state] = true end
          p.separator ""
          p.separator "Datamapper options:"
          p.on("--dm-db URL", "Datamapper database [#{options[:dm_db]}]") do |u| options[:dm_db] = u end
          p.on("--dm-log FILE", "Datamapper log file [#{options[:dm_log]}]") do |n| options[:dm_log] = n end
          p.on("--dm-auto-upgrade", "Run Datamapper's auto upgrade") do |n| options[:dm_auto_upgrade] = true end
          p.separator ""
        end,
        :pre_run => lambda do |opts|
          init_logger()
          init_data_mapper(opts)
          load_test_state(opts) if opts[:load_test_state]
        end
      }


      #Thin::Logging.debug = true
      require 'omf_common/thin/runner'
      OMF::Common::Thin::Runner.new(ARGV, opts).run!
    end
  end # class
end # module




