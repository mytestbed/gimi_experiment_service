
require 'omf-sfa/am/am-rest/rest_handler'
require 'omf-sfa/resource/project'
require 'gimi/exp_service/user_handler'
require 'gimi/exp_service/experiment_handler'

module GIMI::ExperimentService

  # Handles the collection of projects on this AM.
  #
  class ProjectHandler < OMF::SFA::AM::Rest::RestHandler

    def initialize(opts = {})
      super
      @resource_class = OMF::SFA::Resource::Project

      # Define handlers
      opts[:project_handler] = self
      @coll_handlers = {
        users: (opts[:user_handler] || UserHandler.new(opts)),
        experiments: (opts[:experiment_handler] || ExperimentHandler.new(opts))
      }
    end

    # SUPPORTING FUNCTIONS

    def show_resource_list(opts)
      authenticator = Thread.current["authenticator"]
      projects = nil
      if user = opts[:context]
        projects = user.projects
      else
        projects = OMF::SFA::Resource::Project.all()
      end
      show_resources(projects, :projects, opts)
    end

  end
end
