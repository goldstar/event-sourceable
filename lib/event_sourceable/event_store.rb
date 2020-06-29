module EventSourceable
  class EventStore < ActiveRecord::Base
    self.abstract_class = true
    self.inheritance_column = :_type_disabled
    
    #TODO: Implement meta-data
    #TODO: Implement dispatching

    before_create :set_type, :apply_and_persist

    scope :recent_first, -> { reorder('id DESC')}

    after_initialize do
      self.data ||= {}
      self.metadata ||= {}
    end

    attr_accessor :event_name
    def set_type
      return if type.present?
      self.type = compute_event_class_name(event_name)
    end

    def event_class
      @event_class ||= begin
        Object.const_get(type)
      rescue  NameError
        raise NotImplementedError.new("#{type} event does not exist.")
      end
    end

    # Return the aggregate that the event will apply to
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

    # Apply the transformation to the aggregate and save it.
    private def apply_and_persist
      # Lock! (all good, we're in the ActiveRecord callback chain transaction)
      aggregate.lock! if aggregate.persisted?

      # Apply!
      event = event_class.new(aggregate, **data)
      event.apply
      self.metadata.merge!(event.metadata) if self.new_record?

      # Set updated_at
      if aggregate.respond_to?(:updated_at=) 
        aggregate.updated_at ||= self.created_at
      end
      
      # Persist!
      aggregate.save!
      self.aggregate_id = aggregate.id if aggregate_id.nil?
    end

    def self.aggregate_name
      @aggregate_name ||= begin
        associations = reflect_on_all_associations(:belongs_to)
        raise "Events must belong_to only their aggregate" if associations.count != 1
        associations.first.name
      end
    end

    delegate :aggregate_name, to: :class

    # private def dispatch
      # Events::Dispatcher.dispatch(self)
    # end
  end
end