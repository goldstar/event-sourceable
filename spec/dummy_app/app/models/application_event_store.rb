class ApplicationEventStore < EventSourceable::EventStore
  self.abstract_class = true
  
  # For databases like MySQL that do not have native JSON columns,
  # add serializers.  Not required for postgres
  serialize :data, JSON  
  serialize :metadata, JSON
  
  # configure how to compute table names for event stores.
  def self.compute_event_table_name(model)
    # users => user_event_store
    "#{model.table_name.singularize}_event_store"    
    
    # users => user_events
    # "#{model.table_name.singularize}_events"       
  end

end