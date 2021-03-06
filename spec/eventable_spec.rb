require 'spec_helper'

RSpec.describe Sourced::Eventable do
  module ETE
    UserCreated = Sourced::Event.define('users.created')
    NameChanged = Sourced::Event.define('users.name_changed') do
      field(:name).type(:string)
    end
    AgeChanged = Sourced::Event.define('users.age_changed') do
      field(:age).type(:integer)
    end
  end

  let(:user_class) {
    Class.new do
      include Sourced::Eventable
      attr_reader :id, :name

      on ETE::UserCreated do |event|
        @id = event.aggregate_id
      end

      on 'users.name_changed' do |event|
        @name = event.name
      end
    end
  }

  describe '#apply' do
    it 'updates state and collects events' do
      id = Sourced.uuid
      user = user_class.new
      user.apply ETE::UserCreated.instance(aggregate_id: id)
      user.apply ETE::NameChanged.instance(name: 'Ismael')
      expect(user.id).to eq id
      expect(user.name).to eq 'Ismael'
      topics = %w(users.created users.name_changed)
      expect(user.events.map(&:topic)).to eq topics
      expect(user.clear_events.map(&:topic)).to eq topics
      expect(user.events.size).to eq 0
    end

    it 'does not collect when collect: false' do
      id = Sourced.uuid
      user = user_class.new
      user.apply ETE::UserCreated.instance(aggregate_id: id), collect: false

      expect(user.id).to eq id
      expect(user.events.size).to eq 0
    end
  end

  it 'inherits handlers' do
    sub_class = Class.new(user_class) do
      attr_reader :title, :age

      # register a second handler for same event
      on ETE::NameChanged do |event|
        @title = "Mr. #{event.name}"
      end

      on ETE::AgeChanged do |event|
        @age = event.age
      end
    end

    id = Sourced.uuid
    user = sub_class.new
    user.apply ETE::UserCreated.instance(aggregate_id: id)
    user.apply ETE::NameChanged.instance(name: 'Ismael')
    user.apply ETE::AgeChanged.instance(age: 41)

    expect(user.name).to eq 'Ismael'
    expect(user.title).to eq 'Mr. Ismael'
    expect(user.age).to eq 41
  end
end

