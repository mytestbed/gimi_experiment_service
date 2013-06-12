
require 'omf-sfa/am/am-rest/rest_handler'
#require 'omf-sfa/am/am-rest/experiment_handler'
require 'gimi/resource/experiment'

module GIMI::ExperimentService

  # Handles the collection of experiments on this AM.
  #
  class ExperimentHandler < OMF::SFA::AM::Rest::RestHandler

    def initialize(opts = {})
      super
      opts[:experiment_handler] = self
      @project_handler = opts[:project_handler] = ProjectHandler.new(opts)
    end

    def find_handler(path, opts)
      debug "experiment:find_handler: path; '#{path}' opts: #{opts}"
      experiment_id = opts[:resource_uri] = path.shift
      if experiment_id
        experiment = opts[:experiment] = find_resource(experiment_id, GIMI::Resource::Experiment)
      end
      return self if path.empty?

      comp = path.shift
      raise OMF::SFA::AM::Rest::UnknownResourceException.new "Unknown sub collection '#{comp}' for experiment '#{experiment_id}'."
    end

    def on_get(experiment_uri, opts)
      debug 'GET: experiment_uri: "', experiment_uri, '"'
      if experiment_uri
        experiment = opts[:experiment]
        show_resource_status(experiment, opts)
        #show_experiment_status(experiment, opts)
      else
        show_experiments(opts)
      end
    end

    def on_post(experiment_uri, opts)
      debug 'POST: experiment_uri: "', experiment_uri, '" - ', opts.inspect
      description, format = parse_body(opts, [:json, :form])

      if experiment_uri
        experiment = opts[:experiment]
        modify_experiment(experiment, opts)
      else
        experiment = create_experiment(description, opts)
      end

      show_resource_status(experiment, opts)
    end

    def on_delete(experiment_uri, opts)
      if experiment = opts[:experiment]
        debug "Delete experiment #{experiment}"
        project = experiment.project
        res = show_deleted_resource(experiment.uuid)
        experiment.destroy
      else
        # Delete ALL experiments for project
        unless project = opts[:project]
          raise OMF::SFA::AM::Rest::BadRequestException.new "Can only create experiments in the context of a project"
        end
        uuid_a = project.experiments.map do |ex|
          debug "Delete experiment #{ex}"
          uuid = ex.uuid
          ex.destroy
          uuid
        end
        res = show_deleted_resources(uuid_a)
      end
      project.reload
      return res
    end

    # SUPPORTING FUNCTIONS


    def show_experiments(opts)
      # authenticator = Thread.current["authenticator"]
      if project = opts[:project]
        experiments = project.experiments
      else
        experiments = GIMI::Resource::Experiment.all()
      end
      show_resources(experiments, :experiments, opts)
    end

    # Create a new experiment within a project. The experiment properties are
    # contained in 'description'
    #
    def create_experiment(description, opts)
      unless project = opts[:project]
        raise OMF::SFA::AM::Rest::BadRequestException.new "Can only create experiments in the context of a project"
      end
      debug "CREATE: #{description.class}--#{description}"
      # Should start with 'experiments'
      if uuid = description['uuid']
        exp = GIMI::Resource::Experiment.first(uuid: uuid)
      elsif name = description['name']
        exp = GIMI::Resource::Experiment.first(name: name, project: project)
      end
      if exp
        # TODO: Modify experiment
      else
        # CREATE experiment
        description[:project] = project
        exp = GIMI::Resource::Experiment.create(description)
      end
      return exp
    end

  end
end
