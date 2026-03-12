# -*- encoding: binary -*-
require "socket"
require "io/wait"

module Kgio
  Socket = ::TCPSocket
  TCPServer = ::TCPServer
  UNIXServer = ::UNIXServer

  class Pipe
    def self.new
      ::IO.pipe
    end
  end
end

module Unicorn
  module KgioCompat
    module Server
      def kgio_tryaccept
        client = accept_nonblock(exception: false)
        client == :wait_readable ? false : client
      end
    end

    module IO
      def kgio_tryread(maxlen)
        read_nonblock(maxlen, exception: false)
      end

      def kgio_trywrite(data)
        write_nonblock(data, exception: false)
      end

      def kgio_read(maxlen, buffer = nil)
        readpartial(maxlen, buffer)
      rescue EOFError
        nil
      end

      def kgio_read!(maxlen, buffer = nil)
        readpartial(maxlen, buffer)
      end
    end

    module Socket
      def kgio_addr
        remote_address.ip_address
      rescue StandardError
        "127.0.0.1"
      end
    end
  end
end

::IO.prepend(Unicorn::KgioCompat::IO)
::BasicSocket.prepend(Unicorn::KgioCompat::Socket)
::TCPServer.prepend(Unicorn::KgioCompat::Server)
::UNIXServer.prepend(Unicorn::KgioCompat::Server)
