require 'gimi/resource'
require 'omf-sfa/resource/oresource'
require 'time'

module GIMI::Resource

  # This class represents a slice in the system.
  #
  class Slice < OMF::SFA::Resource::OResource

    belongs_to :experiment, GIMI::Resource::Experiment, :required => false

    oproperty :manifest, String  # actually XML
    oproperty :valid_until, DataMapper::Property::Time

    def to_hash_long(h, objs, opts = {})
      super
      h[:urn] = self.urn || 'unknown'
      if valid_until = self.valid_until
        h[:valid_until] = valid_until.iso8601
      end
      h[:experiment] = self.experiment.to_hash_brief(opts)
      h
    end

  end # classs
end # module
