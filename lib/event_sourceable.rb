require "event_sourceable/version"
require "event_sourceable/has_events"
require "event_sourceable/event_store"

module EventSourceable
  @metadata = {}
  def self.set_metadata(hash, &block)
    previous_metadata = @metadata
    @metadata = previous_metadata.merge(hash)
    yield
    @metadata = previous_metadata
  end

  def self.metadata
    @metadata
  end
end