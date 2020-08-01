require "spec_helper.rb"

RSpec.describe EventSourceable do
  it "has a version number" do
    expect(EventSourceable::VERSION).not_to be nil
  end

  describe ".metadata" do
    it "has an empty hash at the default metadata" do
      expect(EventSourceable.metadata).to eq({})
    end
  end

  describe ".with_metadata" do
    let(:spy){ double }

    it "should set the metadata inside the yielded blocks" do
      expect(spy).to receive(:metadata).with({outer: 1, inner: 2})

      EventSourceable.with_metadata(outer: 1){ 
        EventSourceable.with_metadata(inner: 2){ 
          spy.metadata( EventSourceable.metadata )
        }
      }
    end

    it "should not change the metadata outside the yielded blocks" do
      allow(spy).to receive(:metadata)

      expect {
        EventSourceable.with_metadata(outer: 1){ 
          EventSourceable.with_metadata(inner: 2){ 
            spy.metadata( EventSourceable.metadata )
          }
        }
      }.to_not change{ EventSourceable.metadata }
    end

    context "when an error is raised in the block" do
      it "still resets metadata" do
        expect {
          EventSourceable.with_metadata(outer: 1) do
            raise StandardError
          end
        }.
        to raise_error(StandardError).
        and not_change{ EventSourceable.metadata }
      end
    end
  end
end
