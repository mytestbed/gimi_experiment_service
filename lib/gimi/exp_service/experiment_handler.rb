
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
      description, format = parse_body(opts, [:json])

      if experiment_uri
        experiment = opts[:experiment]
        modify_experiment(experiment, opts)
      else
        create_experiment(description, opts)
      end

      show_experiments(opts)
    end

    def on_delete(experiment_uri, opts)
      if experiment = opts[:experiment]
        debug "Delete experiment #{experiment}"
        project = experiment.project
        experiment.destroy
      else
        # Delete ALL experiments for project
        unless project = opts[:project]
          raise OMF::SFA::AM::Rest::BadRequestException.new "Can only create experiments in the context of a project"
        end
        project.experiments.each do |ex|
          debug "Delete experiment #{ex}"
          ex.destroy
        end
      end
      project.reload
      show_experiments(opts)
    end

    # SUPPORTING FUNCTIONS


    def show_experiments(opts)
      authenticator = Thread.current["authenticator"]
      prefix = about = opts[:req].path
      if project = opts[:project]
        experiments = project.experiments
      else
        experiments = GIMI::Resource::Experiment.all()
      end
      res = {
        :about => opts[:req].path,
        :experiments => experiments.map do |a|
          a.to_hash_brief(:href_use_class_prefix => true)
        end
      }
      ['application/json', JSON.pretty_generate({:experiments_response => res})]
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
     unless exl = description['experiments']
       raise OMF::SFA::AM::Rest::BadRequestException.new "Expected '{'experiments':[..]}' but got '#{description}'"
     end
     unless exl.is_a? Enumerable
       raise OMF::SFA::AM::Rest::BadRequestException.new "Expected array in '{'experiments':[..]}' but got '#{exl.class}'"
     end
     exl.each do |ed|
       if uuid = ed['uuid']
         exp = GIMI::Resource::Experiment.first(uuid: uuid)
       elsif name = ed['name']
         exp = GIMI::Resource::Experiment.first(name: name, project: project)
       end
       if exp
         # TODO: Modify experiment
       else
         # CREATE experiment
         ed[:project] = project
         exp = GIMI::Resource::Experiment.create(ed)
       end
     end
    end

  end
end
