require "spec_helper.rb"

RSpec.describe EventSourceable do
  it "has a version number" do
    expect(EventSourceable::VERSION).not_to be nil
  end

  describe "metadata" do
    let(:spy){ double }
    it "has an empty hash at the default metadata" do
      expect(EventSourceable.metadata).to eq({})
    end

    it "should set the metadata inside the yielded blocks" do
      expect(spy).to receive(:metadata).with({outer: 1, inner: 2})

      EventSourceable.set_metadata(outer: 1){ 
        EventSourceable.set_metadata(inner: 2){ 
          spy.metadata( EventSourceable.metadata )
        }
      }
    end

    it "should not change the metadata outside the yielded blocks" do
      allow(spy).to receive(:metadata)

      expect {
        EventSourceable.set_metadata(outer: 1){ 
          EventSourceable.set_metadata(inner: 2){ 
            spy.metadata( EventSourceable.metadata )
          }
        }
      }.to_not change{ EventSourceable.metadata }
    end
  end
end
