require "csv"
require "mondo"
require "mondo_export/version"
require "optparse"
require "optparse/date"
require "logger"

module MondoExport
  class MondoExport
    LOGGER = Logger.new(STDOUT)
    DEFAULT_OPTIONS = {
      since: Date.today,
    }
    CSV_HEADERS = {
      id: 'ID',
      merchant: 'PAYEE',
      created: 'DATE',
      amount: 'AMOUNT',
      description: 'DESCRIPTION',
      notes: 'NOTE',
    }

    def call
      options = parse_options
      LOGGER.level = options[:verbose] ? Logger::DEBUG : Logger::INFO
      LOGGER.debug "Successfully parsed options"
      mondo = Mondo::Client.new(token: options[:token])
      mondo.ping
      LOGGER.info "Successfully authenticated to Mondo"
      LOGGER.debug "Fetching transactions since #{options[:since]}"
      transactions = mondo.transactions(
        expand: [:merchant],
        since: options[:since].strftime("%Y-%m-%d"),
        limit: 100,
      )
      LOGGER.info "Fetched #{transactions.count} transactions"
      csv = []
      csv << CSV_HEADERS.values
      csv.concat transactions.map { |t| transaction_to_csv_entry(t).values }
      output_filename = "#{Date.today}-mondo-export.csv"
      File.open(output_filename, "w") do |file|
        csv.map.with_index do |l, i|
          LOGGER.debug "#{i} | #{l.to_csv.strip}"
          file.write l.to_csv
        end
      end
      LOGGER.info "Wrote output in #{output_filename}"
    end

    private

    def transaction_to_csv_entry(transaction)
      merchant = transaction.merchant ? transaction.merchant.name : nil
      {
        id: transaction.id,
        created: transaction.created.strftime("%Y-%m-%d"),
        merchant: merchant,
        amount: transaction.amount.to_s,
        description: transaction.description,
        notes: transaction.notes,
      }
    end

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

      DEFAULT_OPTIONS.merge(options)
    end
  end
end
