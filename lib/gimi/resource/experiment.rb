require 'gimi/resource'
require 'omf-sfa/resource/oresource'
require 'omf-sfa/resource/project'

module GIMI::Resource
  class Experiment < OMF::SFA::Resource::OResource
    belongs_to :project, :model => OMF::SFA::Resource::Project, :required => false
    oproperty :path, String

    before :save do |exp|
      if exp.project
        path = "/geni-#{exp.project.name}/#{exp.name}/"
        info "Write save: write to irods: #{path}"
        begin
          `imkdir -p #{path}`
        rescue => e
          error e.message
        end
      end
    end

    def to_hash_long(h, objs, opts = {})
      super
      if self.project
        h[:project] = self.project.to_hash_brief(opts)
        h[:path] = self.path
      end
      h
    end

    def to_hash_brief(opts = {})
      h = super
      h[:path] = "/geni-#{self.project.name}/#{self.name}/" if self.project
      h
    end
  end # classs
end # module

# Extend Project with Experiments
module OMF::SFA::Resource
  # This class represents a Project which is strictly connected to the notion of the Slice/Account
  #
  class Project < OResource
    has n, :experiments, :model => GIMI::Resource::Experiment
    oproperty :path, String

    before :save do |proj|
      path = "/geni-#{proj.name}/"
      info "Before save: write to irods: #{path}"
      begin
        `imkdir -p #{path}`
      rescue => e
        error e.message
      end
    end

    alias :__to_hash_long :to_hash_long
    def to_hash_long(h, objs, opts = {})
      super
      __to_hash_long(h, objs, opts)
      h[:experiments] = self.experiments.map do |e|
        e.to_hash_brief(opts)
      end
      h
    end

    def to_hash_brief(opts = {})
      h = super
      h[:path] = "/geni-#{self.name}/"
      h
    end
  end
end

