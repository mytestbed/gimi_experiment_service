
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

    def on_post(resource_uri, opts)
      description, format = parse_body(opts, [:json, :form])
      debug 'POST(', resource_uri, '): body(', format, '): "', description, '"'

      description.delete_if { |k, v| v.empty? }

      new_irods_user = description["irods_user"]

      if resource = opts[:resource]
        debug 'POST: Modify ', resource

        existing_irods_user = (resource.irods_user || "").split(',')

        if new_irods_user
          unless existing_irods_user.include?(new_irods_user)
            existing_irods_user << new_irods_user
            description["irods_user"] = existing_irods_user.join(',')

            allow_irods_user_access_project_folder(new_irods_user, resource.name)
          else
            description.delete("irods_user")
          end
        end

        modify_resource(resource, description, opts)
      else
        debug 'POST: Create ', resource_uri
        description["name"] = resource_uri if resource_uri
        resource = create_resource(description, opts)

        if new_irods_user
          allow_irods_user_access_project_folder(new_irods_user, resource.name)
        end
      end

      if resource
        show_resource_status(resource, opts)
      elsif context = opts[:context]
        show_resource_status(context, opts)
      else
        raise "Report me. Should never get here"
      end
    end

    def on_delete(project_uri, opts)
      if project = opts[:resource]
        debug "Delete project #{project}"
        res = show_deleted_resource(project.uuid)
        project.destroy
      else
        # Remove all projects from user
        unless (user = opts[:context]).is_a? OMF::SFA::Resource::User
          raise OMF::SFA::AM::Rest::BadRequestException.new "Can only remove projects in the context of a user"
        end
        user.projects = []
        user.save
        user.reload
        res = show_resource_status(user, opts)
      end
      return res
    end

    private

    def allow_irods_user_access_project_folder(irods_user_name, project_name)
      folder_name = "\"/geniRenci/home/gimiadmin/geni-#{project_name}/\""

      info "Allow #{irods_user_name} to access #{folder_name}"
      begin
        debug `ichmod -M -r own #{irods_user_name} #{folder_name}`
        debug `ichmod inherit #{folder_name}`
      rescue => e
        error e.message
      end
    end

  end
end
