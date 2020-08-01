require "event_sourceable/version"
require "event_sourceable/has_events"
require "event_sourceable/event_store"

module EventSourceable
  def self.metadata
    Thread.current[:event_sourceable_metadata] ||= {}
  end

  def self.with_metadata(hash, &block)
    previous_metadata = metadata
    Thread.current[:event_sourceable_metadata] = previous_metadata.merge(hash)
    begin
      yield
    ensure
      Thread.current[:event_sourceable_metadata] = previous_metadata
    end
  end
end
