
require 'omf-sfa/am/am-rest/rest_handler'
#require 'omf-sfa/am/am-rest/user_handler'
require 'omf-sfa/resource/project'
require 'uuid'

module GIMI::ExperimentService

  # Handles the collection of users on this AM.
  #
  class UserHandler < OMF::SFA::AM::Rest::RestHandler

    def initialize(opts = {})
      super
      @resource_class = OMF::SFA::Resource::User
      # Define handlers
      opts[:user_handler] = self
      @coll_handlers = {
        projects: (opts[:project_handler] || ProjectHandler.new(opts))
      }
    end

    # SUPPORTING FUNCTIONS

    def show_resource_list(opts)
      authenticator = Thread.current["authenticator"]
      prefix = about = opts[:req].path
      if project = opts[:context]
        users = project.users
      else
        users = OMF::SFA::Resource::User.all()
      end
      show_resources(users, :users, opts)
    end

    def remove_resource_from_context(user, context)
      puts (context.users.methods - Object.new.methods).sort
      context.users.delete(user)
      context.save
      debug "REMOVE #{user} from #{context}"
    end

  end
end
