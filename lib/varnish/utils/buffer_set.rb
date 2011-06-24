module Varnish
  module Utils
    class BufferSet
      def initialize(size, nbufs)
        @size = size
        @nbufs = nbufs

        @buffers = []

        setup
      end

      def push(data)
        raise "WTF #{@buffers.length}" unless @buffers.length == @nbufs

        if @buffers[0].length > @size
          if @buffers[1].length > 0
            raise "panic! the next buffer is still full!"
          end

          buf = @buffers.shift
          @buffers << buf

          yield buf
        end

        @buffers.first << data
      end

    private
      def setup
        (0..@nbufs-1).each do |n|
          @buffers[n] = []
          class << @buffers[n]
            include Iter
          end
        end
      end

      module Iter
        def each
          super
          clear
        end
      end
    end
  end
end
