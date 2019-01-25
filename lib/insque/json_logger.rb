module Insque
  class JsonLogger < ::Logger
    attr_accessor :additional_fields

    def initialize(logdev, level: INFO, sync: true, additional_fields: {})
      super logdev
      self.level = level
      logdev.sync = sync if logdev.respond_to?(:sync=)
      @default_formatter = JsonFormatter.new
      @additional_fields = additional_fields
    end

    def format_message(severity, datetime, progname, msg)
      (@formatter || @default_formatter).call(severity, datetime, progname, msg: msg, additional_fields: additional_fields)
    end

    private
    # Severity label for logging (max 5 chars).
    SEV_LABEL = %w(debug info warn error fatal any).each(&:freeze).freeze

    def format_severity(severity)
      SEV_LABEL[severity] || 'any'
    end
  end
end
