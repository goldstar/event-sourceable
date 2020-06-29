module EventSourceable
  module HasEvents

    def self.included(base_class)
      # Create the BaseEvent class
      # class BaseEvent < ApplicationEvent
      #   table_name = ApplicationEvent.compute_event_table_name(aggregate_class)
      #   belongs_to :aggregate, autosave: false
      # end
      event_class = base_class.const_set("EventStore", Class.new(ApplicationEventStore))
      event_class.class_eval do 
        self.table_name = compute_event_table_name(base_class)
        belongs_to base_class.name.underscore.to_sym, autosave: false
      end

      base_class.class_eval do
        has_many :events, class_name: "::#{base_class.name}::EventStore"
      end
    end

    def create_event!(event_name, **data)
      self.class::EventStore.create!(data: data, aggregate: self, event_name: event_name)
      self
    end

  end
end