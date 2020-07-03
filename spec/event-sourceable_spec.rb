require "spec_helper.rb"

RSpec.describe EventSourceable do
  it "has a version number" do
    expect(EventSourceable::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
