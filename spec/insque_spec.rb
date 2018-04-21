require 'redis'
require 'json'
require 'active_support/all'
require 'active_record'
require 'insque'

class User < ActiveRecord::Base
  acts_as_insque_crud

  def set_status value
    update_column :status, value
  end
end

module Insque
  def self.myapp_test msg
    Insque.redis.set msg['message'], msg['params']['value'] 
  end

  def self.myapp_user_update msg
    Insque.redis.set msg['message'], msg['params']['name'] 
  end

  def self.myapp_user_create msg
    Insque.redis.set msg['message'], msg['params']['name'] 
  end

  def self.myapp_user_destroy msg
    Insque.redis.set msg['message'], msg['params']['name'] 
  end
end

RSpec.describe 'insque' do
  before(:all) do
    system "docker swarm init || true"
    system "docker stack deploy -c insque.local.yml insque"
    sleep 10
    Thread.abort_on_exception=true
    Insque.debug = true
    Insque.sender = 'myapp'
    Insque.inbox_ttl = 3
    Insque.redis_config = { host: 'localhost', port: 63790 }
    ActiveRecord::Base.establish_connection(
      :adapter   => 'sqlite3',
      :database  => 'db/test.db'
    )
    ActiveRecord::Base.connection.execute('create table users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, status TEXT);')
  end

  after(:all) do
    system "docker stack rm insque"
    ActiveRecord::Base.connection.execute('drop table users;')
  end

  before(:each) do
    Insque.redis.flushall
  end

  it "can broadcast without listeners" do
    Insque.broadcast :test, value: '123'
  end

  it "sends and recives a message" do
    listener = Thread.new { Insque.listen }
    sleep 1
    expect(Insque.redis.get '{insque}inbox_pointer_myapp').to eq('{insque}inbox_myapp') 
    Insque.broadcast :test, value: '123'
    sleep 1
    listener.exit
    expect(Insque.redis.get 'myapp_test').to eq('123')
    expect(Insque.redis.llen '{insque}processing_myapp').to eq(0)
    sleep 4
    expect(Insque.redis.get '{insque}inbox_pointer_myapp').to be_nil
  end

  it "restarts broken message" do
    janitor = Thread.new { Insque.janitor }
    Insque.redis.lpush('{insque}processing_myapp', { message: 'myapp_test', broadcasted_at: 1.hour.ago }.to_json)
    sleep 3
    expect(Insque.redis.llen '{insque}processing_myapp').to eq(0)
    expect(Insque.redis.llen '{insque}inbox_myapp').to eq(1)
    janitor.exit
  end

  it "executes model method in background" do
    listener = Thread.new { Insque.slow_listen }
    u = User.create! name: 'Jon Doe'
    u.send_later :set_status, 'processed'
    sleep 1
    listener.exit
    u.reload
    expect(u.status).to eq('processed')
  end

  it "broadcasts model changes" do
    listener = Thread.new { Insque.listen }
    sleep 1
    u = User.create! name: 'Test'
    sleep 1
    expect(Insque.redis.get 'myapp_user_create').to eq('Test')
    u.name = 'Test2'
    u.save!
    sleep 1
    expect(Insque.redis.get 'myapp_user_update').to eq('Test2')
    u.destroy
    sleep 1
    expect(Insque.redis.get 'myapp_user_destroy').to eq('Test2')
    listener.exit
  end
end
