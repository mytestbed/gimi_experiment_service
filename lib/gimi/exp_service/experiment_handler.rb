
require 'omf-sfa/am/am-rest/rest_handler'
#require 'omf-sfa/am/am-rest/experiment_handler'
require 'gimi/resource/experiment'

module GIMI::ExperimentService

  # Handles the collection of experiments on this AM.
  #
  class ExperimentHandler < OMF::SFA::AM::Rest::RestHandler

    def initialize(opts = {})
      super
      @resource_class = GIMI::Resource::Experiment

      # Define handlers
      opts[:experiment_handler] = self
      @project_handler = opts[:project_handler] || ProjectHandler.new(opts)
      @coll_handlers = {
        project: lambda do |path, o| # This will force the showing of the SINGLE project
          path.insert(0, o[:context].project.uuid.to_s)
          @project_handler.find_handler(path, o)
        end
      }

    end

    def on_delete(experiment_uri, opts)
      if experiment = opts[:resource]
        debug "Delete experiment #{experiment}"
        res = show_deleted_resource(experiment.uuid)
        experiment.destroy
      else
        # Delete ALL experiments for project
        unless (project = opts[:context]).is_a? OMF::SFA::Resource::Project
          raise OMF::SFA::AM::Rest::BadRequestException.new "Can only delete experiments in the context of a project"
        end
        uuid_a = project.experiments.map do |ex|
          debug "Delete experiment #{ex}"
          uuid = ex.uuid
          ex.destroy
          uuid
        end
        res = show_deleted_resources(uuid_a)
        project.reload
      end
      return res
    end

    # SUPPORTING FUNCTIONS


    def show_resource_list(opts)
      # authenticator = Thread.current["authenticator"]
      if project = opts[:context]
        experiments = project.experiments
      else
        experiments = GIMI::Resource::Experiment.all()
      end
      show_resources(experiments, :experiments, opts)
    end

    # Create a new experiment within a project. The experiment properties are
    # contained in 'description'
    #
    def create_resource(description, opts)
      unless (project = opts[:context]).is_a? OMF::SFA::Resource::Project
        raise OMF::SFA::AM::Rest::BadRequestException.new "Can only create experiments in the context of a project"
      end
      if name = description[:name]
        if (res = @resource_class.first(name: name, project: project))
          return modify_resource(res, description, opts)
        end
      end

      description[:project] = project
      super
    end

  end
end
