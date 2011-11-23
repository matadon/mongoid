require 'mongoid/database_proxy.rb'

#
# Proxy that enables runtime swapping of the MongoDB connection. This is
# not an ideal-solution, performance-wise, as a quick check shows that
# method invocation via method_missing is about three times as slow as
# direct invocation on the object.
#
# What this does allow us to do, however, is very transparently swap out
# Mongo::Connection instances underneath Mongoid, without having to
# rewrite large portions of the codebase. In theory, this should result
# in a relatively painless connection-swapping system.
#
class ConnectionProxy
    def ConnectionProxy.from_uri(*args)
        new(*args)
    end

    def initialize(*args)
        @connection = Mongo::Connection.from_uri(*args)
    end

    def db(name)
        @database ||= DatabaseProxy.new(@connection, name)
    end

    def method_missing(*args, &block)
        @connection.send(*args, &block)
    end
end

# establish a base connection to a DB
# enable temporary overrides in a ThreadLocal
# clear these at the end of the request.
# some sort of connection pooling would be nice, so we don't need to
# reconnect every time. We're only switching databases, not hosts.
