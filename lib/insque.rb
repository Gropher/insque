require "insque/version"
require "redis"
require "json"
require "insque/json_formatter"
require "insque/json_logger"
require "insque/railtie" if defined?(Rails)

module Insque
  DEFAULT_INBOX_TTL = 10800 # seconds
  DEFAULT_PROCESSING_TTL = 3600 # seconds

  def self.inbox_ttl= val
    @inbox_ttl = val
  end

  def self.inbox_ttl
    @inbox_ttl || DEFAULT_INBOX_TTL
  end

  def self.processing_ttl= val
    @processing_ttl = val
  end

  def self.processing_ttl
    @processing_ttl || DEFAULT_PROCESSING_TTL
  end

  def self.redis= redis
    @redis = redis
  end

  def self.redis
    @redis
  end

  def self.logger= l
    @logger = l
  end

  def self.logger
    @logger ||= JsonLogger.new STDOUT, additional_fields: { tag: 'insque' }
  end

  def self.redis_class= klass
    @redis_class = klass
  end

  def self.redis_config
    @redis_config
  end

  def self.redis_config= redis
    @redis_config = redis
    @redis = self.create_redis_connection
  end

  def self.sender= sender
    @sender = sender
    @inbox = "{insque}inbox_#{sender}"
    @inbox_pointer = "{insque}inbox_pointer_#{sender}"
    @processing = "{insque}processing_#{sender}"
    @slow_inbox = "{insque}slow_inbox_#{sender}"
    @slow_processing = "{insque}slow_processing_#{sender}"
    create_send_later_handler
  end

  def self.broadcast message, params = nil, recipient = :any
    keys = []
    case recipient
    when :any
      pointers = @redis.keys('{insque}inbox_pointer_*')
      keys = pointers.count > 0 ? @redis.mget(*pointers) : []
    when :self
      keys = [@inbox]
    when :slow
      keys = [@slow_inbox]
    else
      keys = recipient.is_a?(Array) ? recipient : [recipient]
    end
    value = { message: "#{@sender}_#{message}", params: params, broadcasted_at: Time.now.utc }.to_json
    logger.debug event: :sending, message: value, to: keys.to_json
    @redis.multi do |r|
      keys.each {|k| r.lpush k, value}
    end
  end

  def self.listen worker_name='', redis=nil
    redis ||= create_redis_connection
    do_listen @inbox, @processing, redis, worker_name, @inbox_pointer
  end

  def self.slow_listen worker_name='', redis=nil
    do_listen @slow_inbox, @slow_processing, (redis || create_redis_connection), worker_name
  end

  def self.janitor redis=nil
    real_janitor @inbox, @processing, (redis || create_redis_connection), @inbox_pointer
  end

  def self.slow_janitor redis=nil
    real_janitor @slow_inbox, @slow_processing, (redis || create_redis_connection)
  end

private
  def self.do_listen inbox, processing, redis, worker_name, pointer=nil
    logger.info event: :starting, worker_name: worker_name, inbox: inbox
    loop do
      redis.setex(pointer, inbox_ttl, inbox) if pointer
      message = redis.brpoplpush(inbox, processing, 0)
      begin
        logger.debug event: :receiving, message: message, inbox: inbox
        parsed_message = JSON.parse message
        send(parsed_message['message'], parsed_message) 
      rescue NoMethodError
      rescue => e
        logger.error e
      ensure
        redis.lrem processing, 0, message
      end
    end
  end

  def self.real_janitor inbox, processing, redis, pointer=nil
    loop do
      redis.setex(pointer, inbox_ttl, inbox) if pointer
      redis.watch processing
      errors = []
      restart = []
      delete = []
      redis.lrange(processing, 0, -1).each do |m|
        begin
          parsed_message = JSON.parse(m)
          if parsed_message['restarted_at'] && Time.now.to_i - Time.parse(parsed_message['restarted_at']).to_i > processing_ttl
            errors << m 
            delete << m
          elsif Time.now.to_i - Time.parse(parsed_message['broadcasted_at']).to_i > processing_ttl
            restart << parsed_message.merge(restarted_at: Time.now.utc).to_json
            delete << m
          end
        rescue => e
          logger.error e
        end
      end
      result = redis.multi do |r|
        restart.each {|m| r.lpush inbox, m }
        delete.each {|m| r.lrem processing, 0, m }
      end
      if result
        errors.each {|m| logger.debug event: :deleting, message: m }
        restart.each {|m| logger.debug event: :restarting, message: m }
        logger.info event: :cleaning, status: 'success', inbox: inbox
      else
        logger.info event: :cleaning, status: 'failed', inbox: inbox
      end
      sleep(Random.rand((inbox_ttl.to_f / 10).ceil) + 1)
    end
  end

  def self.create_redis_connection
    (@redis_class || Redis).new @redis_config
  end 

  def self.create_send_later_handler
    define_singleton_method("#{@sender}_send_later") do |msg|
      Kernel.const_get(msg['params']['class']).unscoped.find(msg['params']['id']).send(msg['params']['method'], *msg['params']['args'])      
    end
  end
end

if defined?(ActiveRecord::Base)
  class ActiveRecord::Base
    def send_later(method, *args)
      Insque.broadcast :send_later, { class: self.class.name, id: id, method: method, args: args }, :slow
    end

    def self.acts_as_insque_crud(*args)
      options = args.extract_options!
      excluded = (options[:exclude] || []).map(&:to_s)
      set_callback :commit, :after do
        action = [:create, :update, :destroy].map {|a| a if transaction_include_any_action?([a]) }.compact.first
        params = self.serializable_hash(options).delete_if {|key| (['created_at', 'updated_at'] + excluded).include? key}
        Insque.broadcast :"#{self.class.to_s.underscore}_#{action}", params
      end
    end
  end
end
