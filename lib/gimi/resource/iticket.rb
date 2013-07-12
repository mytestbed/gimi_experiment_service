require 'gimi/resource'
require 'omf-sfa/resource/oresource'

module GIMI::Resource

  # This class represents a user in the system.
  #
  class ITicket < OMF::SFA::Resource::OResource
    oproperty :token, String
    oproperty :path, String  # Directory path
    oproperty :created_at, DataMapper::Property::Time
    oproperty :valid_until, DataMapper::Property::Time

    belongs_to :experiment, GIMI::Resource::Experiment, :required => false

    @@def_duration = 100 * 86400 # 100 days

    def self.default_duration=(duration)
      @@def_duration = duration
    end

    def initialize(*args)
      super
      self.created_at = Time.now
      if self.valid_until == nil
        self.valid_until = Time.now + @@def_duration
      end
    end

    def to_hash_brief(opts = {})
      h = super
      h[:token] = self.token
      h[:path] = self.path
      h
    end
  end # classs
end # module
