module Insque
  class JsonLogger < ::Logger
    attr_accessor :additional_fields
    def initialize(logdev, shift_age = 0, shift_size = 1048576, level: DEBUG,
                 progname: nil, formatter: nil, datetime_format: nil,
shift_period_suffix: '%Y%m%d')
      super
      @default_formatter = JsonFormatter.new
      @additional_fields = {}
    end

    def format_message(severity, datetime, progname, msg)
      (@formatter || @default_formatter).call(severity, datetime, progname, msg, additional_fields)
    end

    private
    # Severity label for logging (max 5 chars).
    SEV_LABEL = %w(debug info warn error fatal any).each(&:freeze).freeze

    def format_severity(severity)
      SEV_LABEL[severity] || 'any'
    end
  end
end
