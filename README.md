# EventSourceable

EventSourceable is a minimal way of adding event sourcing to ActiveRecord models. It was inspired by Kickstarter's d.rip application which Philippe Cruex described in his 2019 Railsconf talk [Event Sourcing Made Simple](https://www.youtube.com/watch?v=ulF6lEFvrKo&feature=emb_title). 

While being minimal and easy to understand, it tries to keep boilerplate code and repititive code to a minmum.

Some key differences:
  * EventStores (or BaseEvent models) are created by including a module into the model that you want to event source.
  * Event models are plain old ruby objects (inspired by Pundit's Policies)
  * Event models register their own reactors instead of doing so in a separate file
  * Easily set metadata for all events in the scope of a request

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'event-sourceable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install event-sourceable

## Usage

### Add EventStores for the models that you want to event source

Create an ApplicationEventStore. Events stores are ActiveRecord models. For each model (e.g. User in users table) that your event sourcing, you'll have an event store (e.g. User::EventStore in user_event_store table).

```ruby
# /app/models/application_event_store.rb

class ApplicationEventStore < EventSourceable::EventStore
  self.abstract_class = true
  
  # For databases like MySQL that do not have native JSON columns,
  # add serializers.  Not required for postgres
  # serialize :data, JSON  
  # serialize :metadata, JSON
  
  # configure how to compute table names for event stores.
  def self.compute_event_table_name(model)
    # users => user_event_store
    "#{model.table_name.singularize}_event_store"    
    
    # users => user_events
    # "#{model.table_name.singularize}_events"       
  end

  # configure how to compute class names for events.
  def compute_event_class_name(event)
    # User::EventStore => User::CreatedEvent
    self.class.name.gsub(/::EventStore/, "::#{event.to_s.camelize}Event")         
    
    # User::EventStore => Events::User::Created
    # "Events::"+self.class.name.gsub(/::EventStore/, "::#{event.to_s.camelize}") 
  end
end
```

For each model that you want to event source, include the HasEvents concern and create the table.

```ruby
# app/model/user.rb

class User
  include EventSourceable::HasEvents

  # which does saves you from this boilerplate:
  # class EventStore < ApplicationEventStore
  #   self.table_name = compute_event_table_name(User)
  #   belongs_to :user, autosave: false
  # end
  # 
  # has_many :events, class_name: "::User::EventStore"
  # 
  # def create_event!(event_name, **data)
  #   User::EventStore.create!(data: data, aggregate: self, event_name: event_name)
  #   self
  # end
end
```

And for each model, create your event store database table.

```ruby
class CreateUserEventStore < ActiveRecord::Migration[6.0]
  def change
    create_table(:user_event_store) do |t|
      t.string :type, null: false
      t.references :user, null: false, index: { name: :user_event_store_aggregate_index } 
      t.jsonb :data, null: false        # if your database doesn't support jsonb, use text
      t.jsonb :metadata, null: false    # and add serializers to your ApplicationEventStore
      t.datetime :created_at, null: false
    end
  end  
end
```

### Define Events

Events in EventSourceable are plain old ruby objects, initialized with 2 arguments (record and data) and respond to 3 methods (data, metadata and apply).  Start by creating an ApplicationEvent that all your events can inherit from.

```ruby
# app/events/application_event  (or anywhere in your load path)

class ApplicationEvent # or whatever you want to call it
  attr_reader :data, :metadata, :record

  def initialize(record, data = {})
    data.symbolize_keys!
    @record = record
    @metadata = data.delete(:metadata) || {}
    @data = data
  end

  def apply
    changes_to_apply = changes
    unless changes_to_apply.is_a?(Hash)
      raise TypeError.new("The method changes must return a Hash") 
    end
    record.assign_attributes(changes_to_apply)
  end
  
  private

  private def changes
    raise NotImplementedError
  end
end
```

and then define each event in its own class.

```ruby
# The class name should match the pattern in ApplicationEventStore#compute_event_class_name
class User::RegisteredEvent < ApplicationEvent 
  
  # Define an apply method
  def apply
    record.assign_attributes(
      email: data[:email],
      encrypted_password: data[:encrypted_password]
      # everything passed into data is recorded, so remove sensitive data before creating events
      # don't include created_at or updated_at, those will be assing automatically
    )
  end

end
```

### Apply Events

You apply events by creating records in the event store.

```ruby
user = User.new

# long-form:
User::EventStore.create!(data: data, aggregate: user, event_name: :registered) # returns the create record in the event store

# short-form
user.apply_event!(:registered, data) # returns user
```

#### Testing your Events

Most event classes are so simple that you can simply test their application to a record.

```ruby
require "rails_helper"

RSpec.describe User::RegisteredEvent do
  let(:user){ User.new }
  let(:data) {
    {
      email: "bob@example.com",
      encrypted_password: "---password---",
    }
  }
  let(:event){ user.apply_event!(:registered, data) }

  it "sets attributes correctly on the event aggregate" do
    expect{ event }
      .to change{ user.email }.to(data[:email])
      .and change{ user.encrypted_password }.to(data[:encrypted_password])
      .and change{ User.count }.by(1)
  end  
end
```

### Defining Reactors

### Setting Metadata on your Events

Metadata for an event can be for specific events or as wrapper for all events created inside the wrapper.

The example `ApplicationEvent` allows you to pass metadata in with the event data. You can also just define a metadata method on your event object.

```ruby
class User::RegisteredEvent < ApplicationEvent 
  ...
  def metadata
    {version: '1'}
  end
end
```

The default metadata for events can be set using a wrapper, for example in your `ApplicationController` as an `around_action`.

```ruby
class ApplicationController < ActionController::Base
  around_action :set_event_sourceble_metadata

  def set_event_sourceable_metadata
    EventSourceable.with_metadata(ip: request.remote_ip, current_user_id: current_user.id){ yield }
  end
end
```

You can also nest them, having metadata set at the rack level, application controller, or an individual controller.

```ruby
> puts EventSourceable.metadata
> {}
> EventSourceable.with_metadata(outer: 1){ EventSourceable.with_metadata(inner: 2){ puts EventSourceable.metadata } }
> {outer: 1, inner: 2}
> puts EventSourceable.metadata
> {}
> EventSourceable.with_metadata(outer: 1){ EventSourceable.with_metadata(outer: 2){ puts EventSourceable.metadata } }
> {outer: 2}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/goldstar/event-sourceable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Event::Sourceable project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/event-sourceable/blob/master/CODE_OF_CONDUCT.md).
