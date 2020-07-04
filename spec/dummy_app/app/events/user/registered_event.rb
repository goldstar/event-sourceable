class User::RegisteredEvent
  attr_accessor :data, :metadata

  def initialize(record, data)
    @record = record
    @metadata = data.delete("metadata") || {}
    @data = data.symbolize_keys
  end

  def apply
    @record.assign_attributes(
      email: data[:email],
      name: data[:name]
    )
  end

end