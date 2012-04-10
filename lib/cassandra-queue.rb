#!/usr/bin/env ruby
# queue = CassandraQueue::Queue.get_queue("myqueue", "KeyspaceName", "localhost:9160")

require "cassandra"
include SimpleUUID

DEFAULT_KEYSPACE      = "CassandraQueueInfo"
DEFAULT_SERVERS       = ["127.0.0.1:9160"]
DEFAULT_STRING_QUEUE  = :StringQueue
DEFAULT_BYTES_QUEUE   = :BytesQueue
module CassandraQueue
  # Singleton class that manages our cassandra queues
  class QueueManager
    def self.queues
      @queues ||= {}
    end

    def self.queue(qid, string_queue, keyspace, servers)
      key = :"#{qid}_#{string_queue}_#{keyspace}_#{servers.flatten.join(',')}"
      queues[key] ||= Queue.new(qid, string_queue, keyspace, servers)
    end
  end

  class Queue
    # Entry point for using a queue.  Class method which will return you a queue object for that UUID
    def self.retrieve(qid, opts = {})
      string_queue = opts[:string_queue] || false
      keyspace = opts[:keyspace] || DEFAULT_KEYSPACE
      servers = opts[:servers] || DEFAULT_SERVERS
      QueueManager.queue(qid, string_queue, keyspace, servers)
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

    alias :add      :insert

    def push(payload, options = {})
      insert(payload, Time.now, options)
    end

    alias :enqueue  :push

    # Removes a TimeUUID, and it's payload, from the queue
    def remove(timeUUID, options = {})
      @client.remove(@queue_cf, @key, timeUUID, options)
    end

    alias :delete :remove

    # Show the first 100 elements of the queue by default, for things such as failure recovery
    def list(get_times = false, options = {})
      list = @client.get(@queue_cf, @key, options)
      get_times ? list : list.values
    end

    alias :list_queue :list
    alias :queue      :list

    def payloads(options = {})
      list(false, options)
    end

    alias :messages :payloads
    alias :values   :payloads

    def empty?(options = {})
      list(true, options).empty?
    end

    # Show the first (oldest) element in the queue
    # Returns payload [TimeUUID, payload] as a two element array
    def peek(get_time = false, options = {})
      options.merge(:count => 1)
      payload = @client.get(@queue_cf, @key, options).first
      payload && !get_time ? payload.last : payload
    end

    alias :front      :peek
    alias :get_first  :peek

    def pop(get_time = false, options = {})
      item = peek(true, options)
      return nil if item.nil?
      remove(item.first, options)
      get_time ? item : item.last
    end

    alias :dequeue  :pop

    private_class_method :new

    private
    def initialize(qid, string_queue, keyspace, servers)
      @key = qid_to_rowkey qid
      # Set cassandra client if it has not already been set
      @client = create_client(keyspace, servers)
      @queue_cf = string_queue ? DEFAULT_STRING_QUEUE : DEFAULT_BYTES_QUEUE
    end

    def qid_to_rowkey(qid)
      qid
    end

    def create_client(keyspace, servers)
      ::Cassandra.new(keyspace, [servers].flatten)
    end
  end
end