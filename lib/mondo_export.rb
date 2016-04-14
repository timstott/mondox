require "mondo"
require "mondo_export/version"
require "optparse"
require "optparse/date"
require "logger"

module MondoExport
  class MondoExport
    LOGGER = Logger.new(STDOUT)

    def call
      options = parse_options
      LOGGER.level = options[:verbose] ? Logger::DEBUG : Logger::INFO
      LOGGER.debug "Successfully parsed options"
      mondo = Mondo::Client.new(token: options[:token])
      mondo.ping
      LOGGER.info "Successfully authenticated to Mondo"
      transactions = mondo.transactions(
        since: options[:since].strftime("%Y-%m-%d"),
        limit: 100,
      )
      LOGGER.info "Fetched #{transactions.count} transactions"
    end

    private

    def parse_options
      options = {
        token: ENV.fetch("MONDO_TOKEN") { LOGGER.error "Your Mondo authentication token needs to be available under the MONDO_TOKEN env" },
      }
      OptionParser.new do |opts|
        opts.banner = "Usage: MONDO_TOKEN=c95132d mondox [options]"

        opts.on("-s", "--since DATE", Date, "export transactions from yyyy-mm-dd (inclusive)") do |v|
          options[:since] = v
        end

        opts.on("-v", "--verbose", "run verbosely") do |v|
          options[:verbose] = v
        end
      end.parse!
      options
    end
  end
end
