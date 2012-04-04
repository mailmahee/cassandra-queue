#!/usr/bin/env ruby
# queue = CassandraQueue::Queue.get_queue("myqueue", "KeyspaceName", "localhost:9160")

require "cassandra"
include SimpleUUID

DEFAULT_KEYSPACE = "CassandraQueueInfo"
DEFAULT_SERVERS  = ["127.0.0.1:9160"]
DEFAULT_QUEUE_CF = :Queue

module CassandraQueue
  # Singleton class that manages our cassandra queues
  class QueueManager
    def self.queues
      @queues ||= {}
    end

    def self.queue(qid, keyspace, servers)
      key = :"#{qid}_#{keyspace}_#{servers.flatten.join(',')}"
      queues[key] ||= Queue.new(qid, keyspace, servers)
    end
  end

  class Queue
    # Entry point for using a queue.  Class method which will return you a queue object for that UUID
    def self.retrieve(qid, keyspace = DEFAULT_KEYSPACE, servers = DEFAULT_SERVERS)
      QueueManager.queue(qid, keyspace, servers)
    end

    class << self
      alias :get_queue  :retrieve
      alias :get        :retrieve
    end
    # Takes a payload, throws it on the queue, and returns the TimeUUID that was created for it
    def insert(payload, time = Time.now, options = {})
      timeUUID = UUID.new(time)
      @client.insert(@queue_cf, @key, { timeUUID => payload }, options)
      timeUUID
    end

    # Removes a TimeUUID, and it's message, from the queue
    def delete(timeUUID, options = {})
      @client.remove(@queue_cf, @key, timeUUID, options)
    end

    # Show the first 100 elements of the queue by default, for things such as failure recovery
    def list(options = {})
      @client.get(@queue_cf, @key, options)
    end

    alias :list_queue :list
    alias :queue      :list
    alias :messages   :list

    def empty?(options = {})
      list(options).empty?
    end

    # Show the first (oldest) element in the queue
    # Returns [TimeUUID, payload] as a two element array
    def peek(options = {})
      options.merge(:count => 1)
      @client.get(@queue_cf, @key, options).first
    end

    alias :first    :peek
    alias :front    :peek
    alias :get_next :peek

    private
    def initialize(qid, keyspace, servers)
      # Fail if called directly.  We want queues to be managed by QueueManager
      raise "Please create a managed queue using Queue::get_queue" unless caller[1] =~ /in `queue'/

      @key = qid_to_rowkey qid
      # Set cassandra client if it has not already been set
      @client ||= create_client(keyspace, servers)
      @queue_cf = DEFAULT_QUEUE_CF
    end

    def qid_to_rowkey(qid)
      qid
    end

    def create_client(keyspace, servers)
      ::Cassandra.new(keyspace, servers.flatten)
    end
  end
end