module RSpec
  module Sidekiq
    class Configuration
      attr_accessor :clear_all_enqueued_jobs,
                    :enable_terminal_colours,
                    :warn_unsupported_mocking_library,
                    :warn_when_jobs_not_processed_by_sidekiq

      def initialize
        @clear_all_enqueued_jobs = true
        @enable_terminal_colours = true
        @warn_unsupported_mocking_library = true
        @warn_when_jobs_not_processed_by_sidekiq = true
      end
    end
  end
end
