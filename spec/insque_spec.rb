require 'redis'
require 'json'
require 'insque'
require 'active_support/all'

module Insque
  def self.test_test msg
    Insque.redis.setex msg['message'], 10, msg['params']['value'] 
    Thread.current.exit
  end
end

RSpec.describe 'streamer' do
  before(:all) do
    system "docker swarm init || true"
    system "docker stack deploy -c redis.local.yml redis"
    sleep 10
    Thread.abort_on_exception=true
    Insque.debug = true
    Insque.sender = 'test'
    Insque.inbox_ttl = 3
    Insque.redis_config = { host: 'localhost', port: 63790 }
  end

  after(:all) do
    system "docker stack rm redis"
  end

  it "can broadcast without listeners" do
    Insque.broadcast :test, value: '123'
  end

  it "sends and recives a message" do
    listener = Thread.new { Insque.listen }
    sleep 1
    expect(Insque.redis.get '{insque}inbox_pointer_test').to eq('{insque}inbox_test') 
    Insque.broadcast :test, value: '123'
    listener.join
    expect(Insque.redis.get 'test_test').to eq('123')
    expect(Insque.redis.llen '{insque}processing_test').to eq(0)
    sleep 4
    expect(Insque.redis.get '{insque}inbox_pointer_test').to be_nil
  end

  it "restarts broken message" do
    janitor = Thread.new { Insque.janitor }
    Insque.redis.lpush('{insque}processing_test', { message: 'test_test', broadcasted_at: 1.hour.ago }.to_json)
    sleep 3
    expect(Insque.redis.llen '{insque}processing_test').to eq(0)
    expect(Insque.redis.llen '{insque}inbox_test').to eq(1)
    janitor.exit
  end
end
