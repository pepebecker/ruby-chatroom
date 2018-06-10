#!/usr/bin/ruby

require "socket"
require "optparse"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-p", "--port", "Server port") do |p|
    options[:port] = p
  end
end.parse!

class ChatServer

    def initialize(port)
        @descriptors = Array::new
        @serverSocket = TCPServer.new("", port)
        @serverSocket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
        printf("Chat Server initialized at port %d\n", port)
        @descriptors.push(@serverSocket)
    end
    
    def run
        while 1
            res = select(@descriptors, nil, nil, nil)
            if res != nil then
                for sock in res[0]
                    if sock == @serverSocket then
                        accept_new_connection
                    else
                        if sock.eof? then
                            str = sprintf("Client left %s:%s\n", sock.peeraddr[2], sock.peeraddr[1])
                            broadcast_string(str, sock)
                            system('afplay /System/Library/Sounds/Hero.aiff')
                            sock.close
                            @descriptors.delete(sock)
                        else
                            str = sprintf("[%s|%s]: %s", sock.peeraddr[2], sock.peeraddr[1], sock.gets())
                            broadcast_string(str, sock)
                        end
                    end
                end
            end
        end
    end
    
    private
    
    def broadcast_string(str, omit_sock)
        @descriptors.each do |clisock|
            if clisock != @serverSocket && clisock != omit_sock
                clisock.write(str)
            end
        end
    end
    
    def accept_new_connection
        newsock = @serverSocket.accept
        @descriptors.push(newsock)
        newsock.write("You have been accepted into the Ruby Chat Server!\n")
        str = sprintf("Cliend joined %s:%s\n", newsock.peeraddr[2], newsock.peeraddr[1])
        system('afplay /System/Library/Sounds/Hero.aiff')
        broadcast_string(str, newsock)
    end

end

if options[:port] then
  myChatServer = ChatServer.new(ARGV[0].to_i)
  myChatServer.run
else
  printf("You have to specify a port with option -p\n")
end