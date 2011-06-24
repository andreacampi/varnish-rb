require 'eventmachine'
require 'varnish/utils'

module EventMachine
  #
  # A subclass of EM::Channel that implements double buffering (using a
  # circular array of arrays) to achieve higher packet rate.
  #
  # The buffer size and the number of buffers are critical to achieving good
  # performance, you may need to tune them.
  #
  class BufferedChannel < EM::Channel
    def initialize
      super
      @buffer = Varnish::Utils::BufferSet.new(2000, 200)
    end

    def push(*items)
      @buffer.push(*items) do |buf|
        super
      end
    end
  end
end
