
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

    # def on_put(project_uri, opts)
      # project = opts[:project] = OMF::SFA::user::Sliver.first_or_create(:name => opts[:project_id])
      # configure_sliver(sliver, opts)
      # show_sliver_status(sliver, opts)
    # end

    def on_delete(project_uri, opts)
      project = opts[:project]
      @am_manager.delete_project(project)

      show_project_status(nil, opts)
    end

    # SUPPORTING FUNCTIONS

    # def show_project_status(project, opts)
      # if project
        # p = opts[:req].path.split('/')[0 .. -2]
        # p << project.uuid.to_s
        # prefix = about = p.join('/')
        # res = {
          # :about => about,
          # :type => 'project',
          # :properties => {
              # #:href => prefix + '/properties',
              # :expires_at => (Time.now + 600).rfc2822
          # },
          # :users => {:href => prefix + '/users'},
          # :experiments => {:href => prefix + '/experiments'},
        # }
      # else
        # res = {:error => 'Unknown project'}
      # end
#
      # ['application/json', JSON.pretty_generate({:project_response => res})]
    # end

    def show_projects(opts)
      authenticator = Thread.current["authenticator"]
      prefix = about = opts[:req].path
      projects = OMF::SFA::Resource::Project.all().collect do |a|
        {
          :name => a.name,
          #:urn => a.urn,
          :uuid => uuid = a.uuid.to_s,
          :href => prefix + '/' + uuid
        }
      end
      res = {
        :about => opts[:req].path,
        :projects => projects
      }

      ['application/json', JSON.pretty_generate({:projects_response => res})]
    end

    # Configure the state of +project+ according to information
    # in the http +req+.
    #
    # Note: It doesn't actually modify the project directly, but parses the
    # the body and delegates the individual entries to the relevant
    # sub collections, like 'users', 'experiments', ...
    #
    def configure_project(project, opts)
      doc, format = parse_body(opts)
      case format
      when :xml
        doc.xpath("//r:users", 'r' => 'http://schema.mytestbed.net/am_rest/0.1').each do |rel|
          @res_handler.put_components_xml(rel, opts)
        end
      else
        raise BadRequestException.new "Unsupported message format '#{format}'"
      end
    end

    # def find_project(project_id)
      # if project_id.start_with?('urn')
        # fopts = {:urn => project_id}
      # else
        # begin
          # fopts = {:uuid => UUIDTools::UUID.parse(project_id)}
        # rescue ArgumentError
          # fopts = {:name => project_id}
        # end
      # end
      # authenticator = Thread.current["authenticator"]
      # project = OMF::SFA::Resource::Project.first(fopts)
    # end
  end
end
