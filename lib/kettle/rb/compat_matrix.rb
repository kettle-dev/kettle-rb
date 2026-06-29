# frozen_string_literal: true

require "rubygems"

module Kettle
  module Rb
    module CompatMatrix
      Entry = Struct.new(
        :key,
        :ruby,
        :engine,
        :mri,
        :workflow_ruby,
        :rubygems,
        :bundler,
        :rubocop,
        :rubocop_lts,
        :rubocop_lts_requirement,
        :rubocop_ruby_gem,
        :rubocop_ruby_requirement,
        :rubocop_lts_branch,
        :rails,
        :rails_appraisals,
        :notes
      )

      TRUFFLERUBY_NOTES = ["Do not upgrade RubyGems or Bundler on TruffleRuby."].freeze
      TRUFFLERUBY_PSYCH_NOTES = (TRUFFLERUBY_NOTES + ["psych < 5.3 is needed while Gem.ruby_version is below 3.3."]).freeze

      MATRIX_ROWS = [
        ["ruby-1.8", "1.8.7-p374", "ruby", nil, nil, nil, nil, nil, "0.3.1", ["~> 0.3", ">= 0.3.1"], "rubocop-ruby1_8", ["~> 2.0", ">= 2.0.5"], "r1_8-even-v0", "4.0.x", nil, nil],
        ["ruby-1.9", "1.9.3-p551", "ruby", nil, nil, "2.7.11", "1.17.3", "0.41.2", "2.3.1", ["~> 2.3", ">= 2.3.1"], "rubocop-ruby1_9", ["~> 3.0", ">= 3.0.5"], "r1_9-even-v2", "4.2.11.3", nil, nil],
        ["jruby-1.7", "jruby-1.7.27", "jruby", "1.9", "1.9", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ["ruby-2.0", "2.0.0-p648", "ruby", nil, nil, nil, nil, "0.50.0", "4.3.2", ["~> 4.3", ">= 4.3.2"], "rubocop-ruby2_0", ["~> 3.0", ">= 3.0.5"], "r2_0-even-v4", nil, nil, nil],
        ["ruby-2.1", "2.1.10", "ruby", nil, nil, nil, nil, "0.57.2", "6.3.1", ["~> 6.3", ">= 6.3.1"], "rubocop-ruby2_1", ["~> 3.0", ">= 3.0.5"], "r2_1-even-v6", nil, nil, nil],
        ["ruby-2.2", "2.2.10", "ruby", nil, nil, nil, nil, "0.68.1", "8.3.1", ["~> 8.3", ">= 8.3.1"], "rubocop-ruby2_2", ["~> 3.0", ">= 3.0.5"], "r2_2-even-v8", "5.2.8.1", nil, nil],
        ["ruby-2.3", "2.3.8", "ruby", nil, nil, "3.3.27", "2.3.27", "0.81.0", "10.3.1", ["~> 10.3", ">= 10.3.1"], "rubocop-ruby2_3", ["~> 3.0", ">= 3.0.5"], "r2_3-even-v10", nil, nil, nil],
        ["jruby-9.1", "jruby-9.1.17.0", "jruby", "2.3", "2.3", "3.3.27", "2.3.27", nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ["ruby-2.4", "2.4.10", "ruby", nil, nil, nil, nil, "1.12.1", "12.3.1", ["~> 12.3", ">= 12.3.1"], "rubocop-ruby2_4", ["~> 3.0", ">= 3.0.5"], "r2_4-even-v12", nil, ["4.2.11.3", "5.2.8.1"], nil],
        ["ruby-2.5", "2.5.9", "ruby", nil, nil, nil, nil, "1.28.2", "14.3.1", ["~> 14.3", ">= 14.3.1"], "rubocop-ruby2_5", ["~> 3.0", ">= 3.0.5"], "r2_5-even-v14", "6.0.6.1", nil, nil],
        ["jruby-9.2", "jruby-9.2.21.0", "jruby", "2.5", "2.5", "3.3.27", "2.3.27", nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ["ruby-2.6", "2.6.10", "ruby", nil, nil, "3.4.22", "2.4.22", "1.50.2", "16.3.1", ["~> 16.3", ">= 16.3.1"], "rubocop-ruby2_6", ["~> 3.0", ">= 3.0.5"], "r2_6-even-v16", "6.1.7.10", nil, nil],
        ["jruby-9.3", "jruby-9.3.15.0", "jruby", "2.6", "2.6", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, ["JRuby 9.3 can require jar-dependencies ~> 0.4.1 when psych activates a newer default gem stack."]],
        ["ruby-2.7", "2.7.8", "ruby", nil, nil, nil, nil, "1.80.x", "18.4.1", ["~> 18.4", ">= 18.4.1"], "rubocop-ruby2_7", ["~> 3.0", ">= 3.0.5"], "r2_7-even-v18", "7.2.2.2", nil, nil],
        ["ruby-3.0", "3.0.7", "ruby", nil, nil, "3.5.23", "2.5.23", nil, "20.4.1", ["~> 20.4", ">= 20.4.1"], "rubocop-ruby3_0", ["~> 3.0", ">= 3.0.5"], "r3_0-even-v20", nil, nil, nil],
        ["truffleruby-22.3", "truffleruby-22.3.1", "truffleruby", "3.0", "3.0", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, TRUFFLERUBY_NOTES],
        ["ruby-3.1", "3.1.7", "ruby", nil, nil, "3.6.9", "2.6.9", nil, "22.3.1", ["~> 22.3", ">= 22.3.1"], "rubocop-ruby3_1", ["~> 3.0", ">= 3.0.5"], "r3_1-even-v22", nil, nil, nil],
        ["truffleruby-23.0", "truffleruby-23.0.0", "truffleruby", "3.1", "3.0", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, TRUFFLERUBY_PSYCH_NOTES],
        ["jruby-9.4", "jruby-9.4.15.0", "jruby", "3.1", "3.1", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ["ruby-3.2", "3.2.9", "ruby", nil, nil, "3.7.x", "2.7.x", nil, "24.2.1", ["~> 24.2", ">= 24.2.1"], "rubocop-ruby3_2", ["~> 3.0", ">= 3.0.6"], "r3_2-even-v24", "8.0.x", nil, nil],
        ["truffleruby-23.1", "truffleruby-23.1.2", "truffleruby", "3.2", "3.1", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, TRUFFLERUBY_PSYCH_NOTES + ["Use the Ruby 3.1/Rails 7.2 appraisal in CI; Rails 8 failed on this engine."]],
        ["ruby-3.3", "3.3.9", "ruby", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ["truffleruby-24.2", "truffleruby-24.2.2", "truffleruby", "3.3", "3.3", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, TRUFFLERUBY_NOTES],
        ["truffleruby-25.0", "truffleruby-25.0.0", "truffleruby", "3.3", "3.3", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, TRUFFLERUBY_NOTES],
        ["truffleruby-33.0", "truffleruby-33.0.1", "truffleruby", "3.3", "3.3", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, TRUFFLERUBY_NOTES],
        ["ruby-3.4", "3.4.7", "ruby", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ["jruby-10.1", "jruby-10.1.0.0", "jruby", "3.4", "3.4", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        ["truffleruby-34.0", "truffleruby-34.0.1", "truffleruby", "3.4", "3.4", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, TRUFFLERUBY_NOTES]
      ].freeze

      MATRIX = begin
        matrix = {}
        MATRIX_ROWS.each do |row|
          entry = Entry.new(*row)
          entry.rails_appraisals.freeze if entry.rails_appraisals
          entry.notes.freeze if entry.notes
          entry.freeze
          matrix[entry.key] = entry
        end
        matrix.freeze
      end

      WORKFLOW_ENGINE_BY_NAME = begin
        map = {
          "jruby" => "jruby",
          "truffle" => "truffleruby"
        }
        MATRIX.each do |name, entry|
          map[name] = entry.engine unless entry.engine == "ruby"
        end
        map.freeze
      end

      WORKFLOW_RUBY_FLOOR_BY_NAME = begin
        map = {}
        MATRIX.each do |name, entry|
          map[name] = entry.workflow_ruby if entry.workflow_ruby
        end
        map.freeze
      end

      RUBOCOP_ENTRIES = MATRIX.values.select { |entry| entry.rubocop_ruby_gem }.freeze

      class << self
        def entry(key)
          MATRIX[key.to_s]
        end

        def entries
          MATRIX
        end

        def engine_workflow(engine_name)
          WORKFLOW_ENGINE_BY_NAME[engine_name.to_s]
        end

        def workflow_ruby_floor(engine_name)
          WORKFLOW_RUBY_FLOOR_BY_NAME[engine_name.to_s]
        end

        def rubocop_entry_for_minimum_ruby(minimum_ruby)
          version = gem_version(minimum_ruby)
          return RUBOCOP_ENTRIES.first unless version

          selected = nil
          RUBOCOP_ENTRIES.each do |entry|
            entry_version = entry_minimum_ruby_version(entry)
            selected = entry if entry_version && version >= entry_version
          end
          selected || RUBOCOP_ENTRIES.first
        end

        def rubocop_template_tokens(minimum_ruby)
          entry = rubocop_entry_for_minimum_ruby(minimum_ruby)
          [
            requirement_source(entry.rubocop_lts_requirement),
            entry.rubocop_ruby_gem,
            requirement_source(entry.rubocop_ruby_requirement)
          ]
        end

        def rubocop_lts_branch_for_gem(gem_name)
          entry = RUBOCOP_ENTRIES.find { |candidate| candidate.rubocop_ruby_gem == gem_name.to_s }
          entry && entry.rubocop_lts_branch
        end

        def rubocop_ruby_gem?(gem_name)
          !!rubocop_lts_branch_for_gem(gem_name)
        end

        def rubocop_lts_branch_by_gem
          result = {}
          RUBOCOP_ENTRIES.each do |entry|
            result[entry.rubocop_ruby_gem] = entry.rubocop_lts_branch
          end
          result.freeze
        end

        def requirement_source(requirements)
          Array(requirements).map { |requirement| requirement.inspect }.join(", ")
        end

        private

        def entry_minimum_ruby_version(entry)
          match = entry.key.to_s.match(/\Aruby-(\d+\.\d+)\z/)
          match && Gem::Version.new(match[1])
        end

        def gem_version(value)
          return value if value.is_a?(Gem::Version)
          return nil if value.nil? || value.to_s.empty?

          Gem::Version.new(value.to_s)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
