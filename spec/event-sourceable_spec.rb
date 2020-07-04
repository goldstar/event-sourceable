require "spec_helper.rb"

RSpec.describe EventSourceable do
  it "has a version number" do
    expect(EventSourceable::VERSION).not_to be nil
  end
end
