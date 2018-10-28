module Sourced
  module Eventable
    def self.included(base)
      base.extend ClassMethods
    end

    def apply(event, collect: true)
      self.class.handlers[event.topic].each do |handler|
        instance_exec(event, &handler)
        events << event if collect
      end
    end

    def events
      @events ||= []
    end

    module ClassMethods
      def on(event_type, &block)
        key = event_type.respond_to?(:topic) ? event_type.topic : event_type.to_s
        handlers[key] << block
      end

      def handlers
        @handlers ||= Hash.new{|h, k| h[k] = [] }
      end
    end
  end
end