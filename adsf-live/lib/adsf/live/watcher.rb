# frozen_string_literal: true

module Adsf
  module Live
    class Watcher
      def initialize(root_dir:, watch_files: true)
        unless Pathname.new(root_dir).absolute?
          raise ArgumentError, 'Watcher#initialize: The root_path argument must be an absolute path'
        end

        @root_dir = root_dir
        @watch_files = watch_files
        @port = self.class.find_open_port
      end

      attr_reader :port

      def start
        @server = start_server
        @listener = start_listener(@server) if @watch_files
      end

      def stop
        @listener&.stop
        @server&.stop
      end

      def reload(paths)
        @server.reload(paths)
      end

      def start_server
        ::Adsf::Live::WebSocketServer.new(
          host: '0.0.0.0',
          port: @port.to_s,
        )
      end

      def start_listener(server)
        options = {
          latency: 0.0,
          wait_for_delay: 0.0,
        }

        listener =
          Listen.to(@root_dir, options) do |ch_mod, ch_add, ch_del|
            handle_changes(server, [ch_mod, ch_add, ch_del].flatten)
          end
        listener.start
        listener
      end

      def handle_changes(server, chs)
        prefix_length = @root_dir.length
        paths = chs.map { |pa| pa[prefix_length..-1] }
        server.reload(paths)
      end

    private

      def self.find_open_port
        100.times do
          port = rand(49152..65535)
          begin
            # check whether port is available
            TCPServer.new('0.0.0.0', port).close
            return port
          rescue Errno::EADDRINUSE
            # in use; try another port
          end
        end
        raise "Could not find an open port for live reload web socket"
      end
    end
  end
end
