module Insque
  class JsonFormatter < ::Logger::Formatter
    def call(severity, time, progname, msg, additional_fields = {})
      message = case msg
                when ::String
                  { message: msg }
                when ::Hash
                  msg
                when ::Exception
                  {
                    error: "#{ msg.message } (#{ msg.class })",
                    error_class: "#{msg.class}",
                    backtrace: (msg.backtrace || []).join("\n\t")
                  }
                else
                  { message: msg.inspect }
                end
      "#{message.merge(timestamp: time, level: severity).merge(additional_fields).to_json}\n"
    end
  end
end
