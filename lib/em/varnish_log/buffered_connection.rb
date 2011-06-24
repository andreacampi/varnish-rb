require 'eventmachine'
require 'varnish'
require 'varnish/utils'

module EM
  module VarnishLog
    #
    # A (relatively) high-performance subclass of EM::Connection that reads
    # log entries from the Varnish log SHM, buffers them and pushes complete
    # buffers onto the channel passed to its constructor.
    #
    # The buffer size and the number of buffers are critical to achieving good
    # performance. Benchamrks on a modern MBP have shown it is able to push
    # about 150k entries per second (corresponding to about 4k HTTP req/s),
    # using a full CPU.
    #
    class BufferedConnection < EM::Connection
      include Varnish::Utils::Timer

      DEBUG = false

      class << self
        attr_reader :channel

        def start(channel)
          @channel = channel

          EM.connect('localhost', 12345, self)
        end
      end

      def initialize
        @buffer = Varnish::Utils::BufferSet.new(2000, 200)

        timer_init if DEBUG
      end

      def post_init
        vd = Varnish::VSM.VSM_New
        Varnish::VSL.VSL_Setup(vd)
        Varnish::VSL.VSL_Open(vd, 1)

        callback = Proc.new { |*args| cb(*args) }

        Thread.new do
          begin
            Varnish::VSL.VSL_Dispatch(vd, callback, FFI::MemoryPointer.new(:pointer))
          rescue => e
            puts "exception in thread: #{e.inspect}"
          ensure
            EM.stop
          end
        end
      rescue => e
        puts "exception in post_init: #{e.inspect}"
      end

    private
      def cb(priv, tag, fd, len, spec, ptr, bitmap)
        timer_count if DEBUG

        str = ptr.read_string(len)
        data = {:tag => tag, :fd => fd, :data => str, :spec => spec, :bitmap => bitmap}

        @buffer.push(data) do |buf|
          self.class.channel.push(buf)
        end
      rescue => e
        puts "exception in cb: #{e.inspect}"
        puts e.backtrace.join("\n")
        exit
      end
    end
  end
end
