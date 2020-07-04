require "spec_helper.rb"

RSpec.describe EventSourceable::EventStore do
  let(:event_name) { :registered }
  let(:user_id) { 24 }
  let(:user) { User.new(id: user_id) }
  let(:metadata) { {"request_id" => 1} }
  let(:data) { { "metadata" => metadata, "email" => "bob@example.com" } }
  let(:event){ User::EventStore.new(user: user, event_name: event_name, data: data) }

  describe "aggregate method aliases" do
    it "should provide aggregate_name" do
      expect(event.aggregate_name).to eq(:user)
    end

    it "should provide aggregate_id alias" do
      expect(event.aggregate_id).to eq(event.user_id)
    end

    it "should provide aggregate alias" do
      expect(event.aggregate).to eq(event.user)
    end

    it "should provide aggregate_id= alias" do
      expect{ event.aggregate_id = 25 }.to change{event.aggregate_id}.to(25)
    end

    it "should provide aggregate= alias" do
      user = User.new(id: 25)
      expect{ event.aggregate = user }.to change{event.aggregate}.to(user)
    end
  end

  describe "initializers" do 
    let(:event){ User::EventStore.new() }

    it "should set data to empty hash" do
      expect(event.data).to eq({})
    end

    it "should set metadata to empty hash" do
      expect(event.metadata).to eq({})
    end
  end

  describe "#compute_event_class_name" do
    it "should return name" do
      expect( event.compute_event_class_name(:registered) ).to eq("User::RegisteredEvent")
    end
  end

  describe "#event_class" do
    it "should return class constant" do
      expect(event.event_class).to eq(User::RegisteredEvent)
    end
  end

  describe "#apply_event_and_save" do
    let(:user) { User.new }

    context "a new aggregate" do
      it "should apply the event's changes" do
        expect{ event.apply_event_and_save }.to change{ user.email }.from(nil).to( data["email"] )
      end
      it "should set the created_at" do
        expect{ event.apply_event_and_save }.to change{ user.created_at }.from(nil)
      end
      it "should set the updated_at" do
        expect{ event.apply_event_and_save }.to change{ user.updated_at }.from(nil)
      end
      it "should merge in the event's metadata" do
        expect{ event.apply_event_and_save }.to change{ event.metadata }.from( {} ).to( metadata )
      end
      it "should save the aggregate" do
        expect(user).to receive(:save!)
        event.apply_event_and_save
      end
    end

    context "an existing aggregate" do
      before do
        user.updated_at = 2.years.ago
        user.created_at = 2.years.ago
        user.save!
      end
      it "should lock the aggregate if already persisted" do
        expect(user).to receive(:lock!)
        event.apply_event_and_save
      end
      it "should apply the event's changes" do
        expect{ event.apply_event_and_save }.to change{ user.email }.from(nil).to( data["email"] )
      end
      it "should merge in the event's metadata" do
        expect{ event.apply_event_and_save }.to change{ event.metadata }.from( {} ).to( metadata )
      end
      it "shold not the change the created_at" do
        expect{ event.apply_event_and_save }.to_not change{ user.created_at }
      end
      it "should set the updated_at" do
        expect{ event.apply_event_and_save }.to change{ user.reload.updated_at }
      end
      it "should save the aggregate" do
        expect(user).to receive(:save!)
        event.apply_event_and_save
      end
    end
  end
end
