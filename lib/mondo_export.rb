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
      date: 'DATE',
      time: 'TIME',
      merchant: 'PAYEE',
      amount: 'AMOUNT',
      balance: 'BALANCE',
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
      transactions = fetch_transactions_from_mondo(
        client: mondo,
        since: options[:since]
      )
      LOGGER.info "Completed fetch with #{transactions.count} transactions"
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

    def fetch_transactions_from_mondo(client:, since:, acc: [])
      LOGGER.debug "Fetching transactions since #{since}"
      transactions = client.transactions(
        expand: [:merchant],
        since: since.strftime("%Y-%m-%d"),
        limit: 100,
      )
      LOGGER.debug "Fetched #{transactions.count} transactions"
      if (transactions.count < 100)
        acc + transactions
      else
        fetch_transactions_from_mondo(
          client: client,
          since: transactions.last.created,
          acc: acc + transactions
        )
      end
    end

    def transaction_to_csv_entry(transaction)
      merchant = transaction.merchant ? transaction.merchant.name : nil
      {
        id: transaction.id,
        date: transaction.created.strftime("%Y-%m-%d"),
        time: transaction.created,
        merchant: merchant,
        amount: transaction.amount.to_s,
        balance: transaction.account_balance.to_s,
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
