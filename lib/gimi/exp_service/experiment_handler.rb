
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
      puts "experiment:find_handler: path; '#{path}' opts: #{opts}"
      experiment_id = opts[:resource_uri] = path.shift
      if experiment_id
        experiment = opts[:experiment] = find_resource(experiment_id, GIMI::Resource::Experiment)
      end
      return self if path.empty?

      comp = path.shift
      raise UnknownUserException.new "Unknown sub collection '#{comp}' for experiment '#{experiment_id}'."
    end

    def on_get(experiment_uri, opts)
      debug 'get: experiment_uri: "', experiment_uri, '"'
      if experiment_uri
        experiment = opts[:experiment]
        show_resource_status(experiment, opts)
        #show_experiment_status(experiment, opts)
      else
        show_experiments(opts)
      end
    end

    # def on_put(experiment_uri, opts)
      # experiment = opts[:experiment] = OMF::SFA::experiment::Sliver.first_or_create(:name => opts[:experiment_id])
      # configure_sliver(sliver, opts)
      # show_sliver_status(sliver, opts)
    # end

    def on_delete(experiment_uri, opts)
      experiment = opts[:experiment]
      @am_manager.delete_experiment(experiment)

      show_experiment_status(nil, opts)
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

    # Configure the state of +experiment+ according to information
    # in the http +req+.
    #
    # Note: It doesn't actually modify the experiment directly, but parses the
    # the body and delegates the individual entries to the relevant
    # sub collections, like 'experiments', 'experiments', ...
    #
    def configure_experiment(experiment, opts)
      doc, format = parse_body(opts)
      case format
      when :xml
        doc.xpath("//r:experiments", 'r' => 'http://schema.mytestbed.net/am_rest/0.1').each do |rel|
          @res_handler.put_components_xml(rel, opts)
        end
      else
        raise BadRequestException.new "Unsupported message format '#{format}'"
      end
    end

  end
end
