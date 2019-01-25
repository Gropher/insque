module Insque
  class JsonLogger < ::Logger
    attr_accessor :additional_fields

    def format_message(severity, datetime, progname, msg)
      @json_formatter ||= JsonFormatter.new
      @additional_fields ||= {}
      (@formatter || @json_formatter).call(severity, datetime, progname, msg, @additional_fields)
    end

    private
    # Severity label for logging (max 5 chars).
    SEV_LABEL = %w(debug info warn error fatal any).each(&:freeze).freeze

    def format_severity(severity)
      SEV_LABEL[severity] || 'any'
    end
  end
end
