require "insque/version"
require "redis"

module Insque
  def self.debug= debug
    @debug = debug
  end

  def self.redis= redis
    @redis = redis
    @redis.select 7
  end

  def self.sender= sender
    @sender = sender
    @inbox = "insque_inbox_#{sender}"
    @processing = "insque_processing_#{sender}"
    create_send_later_handler
  end

  def self.broadcast message, params = nil, recipient = :any
    keys = []
    case recipient
    when :any
      keys = @redis.smembers 'insque_inboxes'
    when :self
      keys = [@inbox]
    else
      keys = recipient.is_a?(Array) ? recipient : [recipient]
    end
    value = { :message => "#{@sender}_#{message}", :params => params, :broadcasted_at => Time.now.utc }
    log "SENDING: #{value.to_json} TO #{keys.to_json}" if @debug
    keys.each {|k| @redis.lpush k, value.to_json}
  end

  def self.listen worker_name=''
    @redis.sadd 'insque_inboxes', @inbox
    log "#{worker_name} START LISTENING #{@inbox}"
    loop do
      message = @redis.brpoplpush(@inbox, @processing, 0)
      log "#{worker_name} RECEIVING: #{message}" if @debug
      begin
        parsed_message = JSON.parse message
        send(parsed_message['message'], parsed_message) if self.respond_to? parsed_message['message']
      rescue => e
        log "#{worker_name} ========== BROKEN_MESSAGE: #{message} =========="
        log e.inspect
        log e.backtrace
      end
      @redis.lrem @processing, 0, message
    end
  end

  def self.janitor
    loop do
      @redis.watch @processing
      errors = []
      restart = []
      delete = []
      @redis.lrange(@processing, 0, -1).each do |m|
        begin
          parsed_message = JSON.parse(m)
          if parsed_message['restarted_at'] && DateTime.parse(parsed_message['restarted_at']) < 1.hour.ago.utc
            errors << parsed_message 
            delete << parsed_message
          elsif DateTime.parse(parsed_message['broadcasted_at']) < 1.hour.ago.utc
            restart << parsed_message.merge('restarted_at' => Time.now.utc)
            delete << parsed_message
          end
        rescue
          log "========== JANITOR_ERROR: #{m} =========="
        end
      end
      result = @redis.multi do |r|
        restart.each {|m| r.lpush @inbox, m }
        delete.each {|m| r.lrem @processing, 0, m }
      end
      log "CLEANING SUCCESSFULL AT #{Time.now.utc}" if result
      log "CLEANING FAILED AT #{Time.now.utc}" unless result
    end
  end

  private
  def self.log message
    print "#{message}\n"
    STDOUT.flush
  end

  def self.create_send_later_handler
    define_singleton_method("#{@sender}_send_later") do |msg|
      Kernel.const_get(msg['params']['class']).find(msg['params']['id']).send(msg['params']['method'], *msg['params']['args'])      
    end
  end
end

class ActiveRecord::Base
  def send_later(method, *args)
    Insque.broadcast :send_later, {:class => self.class.name, :id => id, :method => method, :args => args }, :self
  end
end
