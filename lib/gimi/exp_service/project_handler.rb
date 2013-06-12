
require 'omf-sfa/am/am-rest/rest_handler'
#require 'omf-sfa/am/am-rest/user_handler'
require 'omf-sfa/resource/project'
require 'gimi/exp_service/user_handler'
require 'gimi/exp_service/experiment_handler'

module GIMI::ExperimentService

  # Handles the collection of projects on this AM.
  #
  class ProjectHandler < OMF::SFA::AM::Rest::RestHandler

    def initialize(opts = {})
      super
      opts[:project_handler] = self
      @user_handler = opts[:user_handler] || UserHandler.new(opts)
      @experiment_handler = opts[:experiment_handler] || ExperimentHandler.new(opts)
    end

    def find_handler(path, opts)
      project_id = opts[:resource_uri] = path.shift
      if project_id
        project = opts[:project] = find_resource(project_id, OMF::SFA::Resource::Project)
      end
      return self if path.empty?

      case comp = path.shift
      when 'users'
        opts[:resource_uri] = path.join('/')
        return @user_handler.find_handler(path, opts)
      when 'experiments'
        opts[:resource_uri] = path.join('/')
        return @experiment_handler.find_handler(path, opts)
      end
      raise UnknownUserException.new "Unknown sub collection '#{comp}' for project '#{project_id}'."
    end

    def on_get(project_uri, opts)
      debug 'get: project_uri: "', project_uri, '"'
      if project_uri
        project = opts[:project]
        #show_project_status(project, opts)
        show_resource_status(project, opts)
      else
        show_projects(opts)
      end
    end

    def on_delete(project_uri, opts)
      if project_uri
        project = opts[:project]
        debug "Delete project #{project}"
        res = show_deleted_resource(project.uuid)
        project.destroy
      else
        # Delete ALL projects
        raise OMF::SFA::AM::Rest::BadRequestException.new "I'm sorry, Dave. I'm afraid I can't do that."
      end
      project.reload
      return res
    end

    # SUPPORTING FUNCTIONS


    def show_projects(opts)
      authenticator = Thread.current["authenticator"]
      projects = OMF::SFA::Resource::Project.all()
      show_resources(projects, :projects, opts)
    end

  end
end
