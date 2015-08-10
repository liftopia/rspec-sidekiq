require 'rspec/core'

if defined? Sidekiq::Batch
  module RSpec
    module Sidekiq
      class NullObject
        def method_missing(*args, &block)
          self
        end
      end

      class NullBatch < NullObject
        attr_reader :bid

        def initialize(bid = nil)
          @bid = bid || SecureRandom.hex(8)
          @callbacks = []
        end

        def status
          NullStatus.new(@bid, @callbacks)
        end

        def on(*args)
          @callbacks << args
        end

        def jobs(*)
          yield
        end
      end

      class NullStatus < NullObject
        attr_reader :bid

        def initialize(bid, callbacks)
          @bid = bid
          @callbacks = callbacks
        end

        def failures
          0
        end

        def join
          ::Sidekiq::Worker.drain_all

          @callbacks.each do |event, callback_class, options|
            if event != :success || failures == 0
              callback_class.new.send("on_#{event}", self, options)
            end
          end
        end

        def total
          ::Sidekiq::Worker.jobs.size
        end
      end
    end
  end

  RSpec.configure do |config|
    config.before(:each) do |example|
      next if example.metadata[:stub_batches] == false

      if mocked_with_mocha?
        Sidekiq::Batch.stubs(:new) { RSpec::Sidekiq::NullBatch.new }
      elsif supports_allow?
        allow(Sidekiq::Batch).to receive(:new)  { RSpec::Sidekiq::NullBatch.new }
        allow(Sidekiq::Batch::Status).to receive(:new)  { RSpec::Sidekiq::NullStatus.new }
      elsif supports_stub?
        stub(Sidekiq::Batch).new { RSpec::Sidekiq::NullBatch.new }
        stub(Sidekiq::Batch::Status).new { RSpec::Sidekiq::NullStatus.new }
      else
        message = '[rspec-sidekiq] The mocking library you\'re using is not supported yet. There will probably be failures.'
        message = "\e[33m#{message}\e[0m" if RSpec::Sidekiq.configuration.enable_terminal_colours
        puts message if RSpec::Sidekiq.configuration.warn_unsupported_mocking_library
      end
    end
  end

  ## Helpers ----------------------------------------------
  def mocked_with_mocha?
    Sidekiq::Batch.respond_to? :stubs
  end

  def supports_allow?
    self.respond_to?(:allow) && self.respond_to?(:receive)
  end

  def supports_stub?
    self.respond_to?(:stub)
  end
end
