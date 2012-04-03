#!/usr/bin/env ruby
# queue = CassandraQueue::Queue.get_queue("myqueue", "KeyspaceName", "localhost:9160")

require "cassandra"
include SimpleUUID

DEFAULT_KEYSPACE = "QueueInfo"
DEFAULT_SERVERS  = ["127.0.0.1:9160"]
DEFAULT_QUEUE_CF = :Queue

module CassandraQueue
  # Singleton class that manages our cassandra queues
  class QueueManager
    def self.queues
      @queues ||= {}
    end

    def self.queue(qid)
      queues[qid.to_sym] ||= Queue.new(qid)
    end
  end

  class Queue
    # Entry point for using a queue.  Class method which will return you a queue object for that UUID
    def self.get_queue(qid)
      QueueManager.queue(qid)
    end

    def initialize(qid, keyspace, servers)
      # Fail if called directly.  We want queues to be managed by QueueManager
      raise "Please create a managed queue using Queue::get_queue" unless caller[1] =~ /in `queue'/

      @key = qid_to_rowkey qid
      # Set cassandra client if it has not already been set
      @client ||= create_client(keyspace)
      @queue_cf = DEFAULT_QUEUE_CF
    end

    def qid_to_rowkey(qid)
      qid
    end

    def create_client(keyspace, servers = DEFAULT_SERVERS)
      ::Cassandra.new(keyspace, servers.flatten)
    end

    # Takes a payload, throws it on the queue, and returns the TimeUUID that was created for it
    def insert(payload, time=Time.now)
      timeUUID = UUID.new(time)
      @client.insert(@queue_cf, @key, timeUUID => payload)
      timeUUID
    end

    # Removes a TimeUUID, and it's message, from the queue
    def delete(timeUUID)
      @client.remove(@queue_cf, @key, timeUUID)
    end

    # Show the current state of the queue, for things such as failure recovery
    def list_queue
      @client.get(@queue_cf, @key)
    end

    # Show the first (oldest) element in the queue
      @client.get(@queue_cf, @key, :count => 1)
  end
end