require 'base64'
require 'socket'

module PusherClient
  class ProxySocket
    PORTS = { 'ws' => 80, 'wss' => 443 }
    SUCCESS_RESPONE = %(HTTP/1.1 200 Connection established)

    def self.connect(origin, proxy, opts = {})
      new(origin, proxy, opts).connect
    end

    def initialize(origin, proxy, opts = {})
      proxy_uri = URI.parse(proxy)
      @socket = TCPSocket.new(proxy_uri.host, proxy_uri.port || 80)
      @origin = URI.parse(origin)
      @headers = {
        'Host' => @origin.host + (@origin.port ? ":#{ @origin.port }" : ''),
        'Connection' => 'keep-alive',
        'Proxy-Connection' => 'keep-alive'
      }
      if @origin.user
        @headers.merge!({
          'Proxy-Authorization' => 'Basic ' + auth_hash
        })
      end
    end

    def connect
      @socket.write(proxy_headers)
      @socket.write(handshake_headers.to_s)

      @socket.flush
      response  = @socket.read
      unless success?(response)
        raise ProxyConnectError, response
      end
      @socket
    end

    private

    # CONNECT server.example.com:80 HTTP/1.1
    # Host: server.example.com:80
    # Proxy-Authorization: basic aGVsbG86d29ybGQ=

    def proxy_headers
      port    = @origin.port || PORTS[@origin.scheme]
      start   = "CONNECT #{ @origin.host }:#{ port } HTTP/1.1"
      headers = @headers.inject([]) { |m, (k, v)| m << "#{k}: #{v}" }

      [start, *headers, '', ''].join("\r\n")
    end

    def handshake_headers
      WebSocket::Handshake::Client.new(:url => @origin.to_s)
    end

    def auth_hash
      Base64.strict_encode64([@origin.user, @origin.password] * ':')
    end

    def success?(resp)
      resp.match(SUCCESS_RESPONE)
    end

    class ProxyConnectError < StandardError; end;
  end
end
