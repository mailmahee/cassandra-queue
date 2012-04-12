require_relative "test_helper"

class QueueTest < Scope::TestCase
  context "with cassandra queue" do
    setup do
      @cassandra = mock("Cassandra")
      ::Cassandra.stubs(:new).returns @cassandra
      @qid = mock "qid"
      @queue = CassandraQueue::Queue.get_queue(@qid)
      @cf = :BytesQueue
      @tid = mock "tuuid"
      SimpleUUID::UUID.stubs(:new).returns(@tid)
      @message = mock "message"
    end

    should "insert into cassandra when asked to" do
      @cassandra.expects(:insert).with(@cf, @qid, {@tid => @message}, {})
      @queue.push(@message)
    end
  end
end