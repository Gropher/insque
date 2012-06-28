require "insque/version"

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

  def self.broadcast message, params, recipient = :any
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
    Rails.logger.info "SENDING: #{value.to_json} TO #{keys.to_json}" if @debug
    keys.each {|k| @redis.lpush k, value.to_json}
  end

  def self.listen 
    @redis.sadd 'insque_inboxes', @inbox
    loop do
      message = @redis.brpoplpush(@inbox, @processing, 0)
      Rails.logger.info "RECEIVING: #{message}" if @debug
      begin
        parsed_message = JSON.parse message
        send(parsed_message['message'], parsed_message) if self.respond_to? parsed_message['message']
      rescue => e
        Rails.logger.info "========== BROKEN_MESSAGE: #{message} =========="
        Rails.logger.info e.inspect
        Rails.logger.info e.backtrace
      end
      @redis.lrem @processing, 0, message
    end
  end

  private

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
