

module GIMI
  module Resource
    class Experiment < OMF::SFA::Resource::OResource; end
    class Slice < OMF::SFA::Resource::OResource; end
  end
end

require 'gimi/resource/iticket'
require 'gimi/resource/experiment'
require 'gimi/resource/slice'
