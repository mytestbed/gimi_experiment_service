require 'gimi/resource'
require 'omf-sfa/resource/oresource'
require 'omf-sfa/resource/project'

module GIMI::Resource

  # This class represents a user in the system.
  #
  class Experiment < OMF::SFA::Resource::OResource
    #oproperty :iticket, :model => GIMI::Resource::ITicket
    has 1, :iticket, :model => GIMI::Resource::ITicket
    has n, :slices, :model => GIMI::Resource::Slice
    belongs_to :project, OMF::SFA::Resource::Project, :required => false

    def to_hash_long(h, objs, opts = {})
      super
      h[:project] = self.project.to_hash(objs, opts)
      h[:slices] = self.slices.map {|s| s.to_hash(objs, opts)}
      h[:iticket] = self.iticket.to_hash(objs, opts) if self.iticket
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

