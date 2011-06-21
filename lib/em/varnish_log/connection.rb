require 'eventmachine'
require 'varnish'

module EM
  module VarnishLog
    #
    # A naive subclass of EM::Connection that reads from the Varnish log SHM
    # and pushes single log entries on the channel passed to its constructor.
    #
    # This class is only provided as a simple example of how to use the
    # Varnish::VSL API; its performance is abysmal so it's only suitable for
    # extremely low workloads in a development environment.
    #
    class Connection < EM::Connection
      class << self
        attr_reader :channel

        def start(channel)
          @channel = channel

          EM.connect('localhost', 12345, self)
        end
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
        str = ptr.read_string(len)
        self.class.channel.push(:tag => tag, :fd => fd, :data => str, :spec => spec, :bitmap => bitmap)
      rescue => e
        puts "exception in cb: #{e.inspect}"
      end
    end
  end
end
