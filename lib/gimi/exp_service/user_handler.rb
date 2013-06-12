
require 'omf-sfa/am/am-rest/rest_handler'
#require 'omf-sfa/am/am-rest/user_handler'
require 'omf-sfa/resource/project'

module GIMI::ExperimentService

  # Handles the collection of users on this AM.
  #
  class UserHandler < OMF::SFA::AM::Rest::RestHandler

    def initialize(opts = {})
      super
      opts[:user_handler] = self
      @project_handler = opts[:project_handler] = ProjectHandler.new(opts)
    end

    def find_handler(path, opts)
      puts "USER:find_handler: path; '#{path}' opts: #{opts}"
      user_id = opts[:resource_uri] = path.shift
      if user_id
        user = opts[:user] = find_resource(user_id, OMF::SFA::Resource::User)
      end
      return self if path.empty?

      case comp = path.shift
      when 'projects'
        opts[:resource_uri] = path.join('/')
        #puts "user >>> '#{r}'::#{user.inspect}"
        return @project_handler.find_handler(path, opts)
      end
      raise UnknownUserException.new "Unknown sub collection '#{comp}' for user '#{user_id}'."
    end

    def on_get(user_uri, opts)
      debug 'get: user_uri: "', user_uri, '"'
      if user_uri
        user = opts[:user]
        show_resource_status(user, opts)
      else
        show_users(opts)
      end
    end


    # SUPPORTING FUNCTIONS

    def show_users(opts)
      authenticator = Thread.current["authenticator"]
      prefix = about = opts[:req].path
      if project = opts[:project]
        users = project.users
      else
        users = OMF::SFA::Resource::User.all()
      end
      show_resources(users, :users, opts)
    end

  end
end
