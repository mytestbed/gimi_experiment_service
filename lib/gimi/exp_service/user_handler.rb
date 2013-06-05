
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
        #show_user_status(user, opts)
      else
        show_users(opts)
      end
    end

    # def on_put(user_uri, opts)
      # user = opts[:user] = OMF::SFA::user::Sliver.first_or_create(:name => opts[:user_id])
      # configure_sliver(sliver, opts)
      # show_sliver_status(sliver, opts)
    # end

    def on_delete(user_uri, opts)
      user = opts[:user]
      @am_manager.delete_user(user)

      show_user_status(nil, opts)
    end

    # SUPPORTING FUNCTIONS

    # def show_user_status(user, opts)
      # if user
        # p = opts[:req].path.split('/')[0 .. -2]
        # p << user.uuid.to_s
        # prefix = about = p.join('/')
        # props = user.to_hash({}, :href_use_class_prefix => true)
        # props.delete(:type)
        # res = {
          # :about => about,
          # :type => 'user',
        # }.merge!(props)
      # else
        # res = {:error => 'Unknown user'}
      # end
#
      # ['application/json', JSON.pretty_generate({:user_response => res})]
    # end

    def show_users(opts)
      authenticator = Thread.current["authenticator"]
      prefix = about = opts[:req].path
      if project = opts[:project]
        users = project.users
      else
        users = OMF::SFA::Resource::User.all()
      end
      res = {
        :about => opts[:req].path,
        :users => users.map do |a|
          a.to_hash_brief(:href_use_class_prefix => true)
          # {
            # :name => a.name,
            # #:urn => a.urn,
            # :uuid => uuid = a.uuid.to_s,
            # :href => a.href() #prefix + '/' + uuid
          # }
        end
      }

      ['application/json', JSON.pretty_generate({:users_response => res})]
    end

    # Configure the state of +user+ according to information
    # in the http +req+.
    #
    # Note: It doesn't actually modify the user directly, but parses the
    # the body and delegates the individual entries to the relevant
    # sub collections, like 'users', 'experiments', ...
    #
    def configure_user(user, opts)
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

  end
end
