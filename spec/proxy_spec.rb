require 'spec_helper'

describe PusherClient::Proxy do
  let(:proxy)  { "https://test.proxy" }
  let(:socket) { double(TCPSocket)    }
  let(:origin)  { "ws://test.host" }
  let(:subject) { described_class.new(origin, proxy) }

  context "connect" do
    before do
      allow(TCPSocket).to receive(:new).and_return(socket)
      allow(socket).to receive(:write).with(connect_string)
    end

    let(:connect_string) {
      "CONNECT test.host:80 HTTP/1.1\r\n" +
      "Host: test.host\r\n" +
      "Connection: keep-alive\r\n" +
      "Proxy-Connection: keep-alive\r\n\r\n"
    }

    it "sends connnect headers" do
      expect(socket).to receive(:write).with(connect_string)

      subject.connect
    end

    context "with basic auth" do
      let(:origin)  { "ws://user:pass@test.host" }

      let(:connect_string) {
        "CONNECT test.host:80 HTTP/1.1\r\n" +
        "Host: test.host\r\n" +
        "Connection: keep-alive\r\n" +
        "Proxy-Connection: keep-alive\r\n" +
        "Proxy-Authorization: Basic dXNlcjpwYXNz\r\n\r\n"
      }
      it "sends connnect headers" do
        expect(socket).to receive(:write).with(connect_string)

        subject.connect
      end
    end

    context "wss scheme" do
      let(:origin)  { "wss://test.host" }
      let(:connect_string) {
        "CONNECT test.host:443 HTTP/1.1\r\n" +
        "Host: test.host\r\n" +
        "Connection: keep-alive\r\n" +
        "Proxy-Connection: keep-alive\r\n\r\n"
      }

      it "sends connnect headers" do
        expect(socket).to receive(:write).with(connect_string)

        subject.connect
      end
    end
  end
end
