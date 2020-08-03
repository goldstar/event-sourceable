require 'active_record'

module EventSourceable
  class EventStore < ::ActiveRecord::Base
    self.abstract_class = true
    self.inheritance_column = :_type_disabled
    
    #TODO: Implement metadata store
    #TODO: Implement dispatching
    #TOOD: Replay events and integrity check

    before_create :set_type, :apply_event_and_save

    scope :recent_first, -> { reorder('id DESC')}

    after_initialize do
      self.data ||= {}
      self.metadata ||= EventSourceable.metadata.dup
      set_type if self.type.nil? && self.event_name.present?
    end

    attr_accessor :event_name
    def set_type
      self.type = compute_event_class_name(event_name)
    end

    def event_class
      @event_class ||= begin
        Object.const_get(type)
      rescue  NameError
        raise NotImplementedError.new("#{type} event does not exist.")
      end
    end

    # configure how to compute class names for events.
    def compute_event_class_name(event)
      # User::EventStore => User::CreatedEvent
      self.class.name.gsub(/::EventStore/, "::#{event.to_s.camelize}Event")         
    end


    # Return the aggregate that the event will apply to
    def self.aggregate_name
      @aggregate_name ||= begin
        associations = reflect_on_all_associations(:belongs_to)
        raise "Events must belong_to only their aggregate" if associations.count != 1
        associations.first.name
      end
    end
    delegate :aggregate_name, to: :class

    def aggregate
      public_send aggregate_name
    end

    def aggregate=(model)
      public_send "#{aggregate_name}=", model
    end

    def aggregate_id
      public_send "#{aggregate_name}_id"
    end

    def aggregate_id=(id)
      public_send "#{aggregate_name}_id=", id
    end

    # Aooly the event to the aggregate and save!
    def apply_event_and_save
      aggregate.lock! if aggregate.persisted?

      # Apply!
      event = event_class.new(aggregate, data)
      event.apply

      # record the metadata
      if event.respond_to?(:metadata)
        self.metadata = metadata.merge(event.metadata || {})
      end

      # Set created_at
      self.created_at = Time.now
      if aggregate.respond_to?(:created_at) && aggregate.new_record?
        aggregate.created_at = self.created_at
      end
      if aggregate.respond_to?(:created_on) && aggregate.new_record?
        aggregate.created_at = self.created_at.to_date
      end

      # Set updated_at
      if aggregate.respond_to?(:updated_at)
        aggregate.updated_at = self.created_at
      end
      if aggregate.respond_to?(:updated_on)
        aggregate.updated_on = self.created_at.to_date
      end
      
      # Persist!
      aggregate.save!
    end

    # private def dispatch
      # Events::Dispatcher.dispatch(self)
    # end
  end
end
