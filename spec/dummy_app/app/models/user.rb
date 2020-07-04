class User < ActiveRecord::Base
  include EventSourceable::HasEvents
end