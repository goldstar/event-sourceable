class CreateUserEventStoreTable < ActiveRecord::Migration[6.0]
  def change
    create_table(:user_event_store) do |t|
      t.string :type, null: false
      t.references :user, null: false, index: { name: :user_event_store_aggregate_index } 
      t.text :data, null: false        # if your database doesn't support jsonb, use text
      t.text :metadata, null: false    # and add serializers to your ApplicationEventStore
      t.datetime :created_at, null: false
    end
  end
end
