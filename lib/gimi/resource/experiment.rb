require 'gimi/resource'
require 'omf-sfa/resource/oresource'
require 'omf-sfa/resource/project'

module GIMI::Resource
  class Experiment < OMF::SFA::Resource::OResource
    belongs_to :project, OMF::SFA::Resource::Project, :required => false
    oproperty :path, String

    after :create do |exp|
      exp.path = "/#{self.project.name}/#{self.name}/" unless exp.project.nil?
      exp.save
      info "After save: write to irods: #{exp.path}"
      begin
        `imkdir -p #{exp.path}`
      rescue => e
        error e.message
        debug e.backtrace.join("\n")
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
      if self.project
        h[:project_name] = self.project.name
        h[:path] = self.path
      end
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

    alias :__to_hash_long :to_hash_long
    def to_hash_long(h, objs, opts = {})
      super
      __to_hash_long(h, objs, opts)
      h[:experiments] = self.experiments.map do |e|
        e.to_hash(objs, opts)
      end
      h
    end

  end
end

