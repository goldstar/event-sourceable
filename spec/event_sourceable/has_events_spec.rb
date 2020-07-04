RSpec.describe EventSourceable::HasEvents do
  let(:event_sourced_class) { User }

  context "when included in a class" do
    it "should add Event Store to class" do
      expect( event_sourced_class::EventStore ).to be_present
    end

    it "should have events association" do
      expect(event_sourced_class.reflect_on_all_associations(:has_many).first.name).to eq(:events)
    end
  end

  describe "apply_event!" do
    let(:event_sourced_instance) { event_sourced_class.new }
    let(:event_name){ :registered }
    let(:data) { {} }
    it "should create event in event store" do
      expect(event_sourced_class::EventStore).to receive(:create!).with(
        data: data, aggregate: event_sourced_instance, event_name: event_name
      )
      event_sourced_instance.apply_event!(event_name, data)
    end
  end
end