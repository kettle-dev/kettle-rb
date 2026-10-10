# frozen_string_literal: true

require "rubygems"
require_relative "platform_support/data"

module Kettle
  module Rb
    # OS-platform support evidence for CI matrix generation, one entry per
    # engine / OS-family pair.
    #
    # The +linux+ / +macos+ / +windows+ vocabulary names CI OS *families*: a
    # fourth platform vocabulary, distinct from Gemfile DSL platform symbols
    # (Ruby implementations), +Gem::Platform+ strings (OS/architecture), and
    # GitHub runner labels (CI hardware). These values select runner labels;
    # they must never be passed to +bundle lock --add-platform+ or a Gemfile
    # +platforms:+ DSL without translation.
    #
    # The data lives in +platform_support/data.rb+ and is regenerated from the
    # GitHub releases API and ruby/setup-ruby by
    # +rake kettle:rb:platform_support:generate+ (see
    # {PlatformSupport::Generator}). Every claim carries a citation, so an
    # unevidenced claim cannot be expressed.
    module PlatformSupport
      RunnerEntry = Struct.new(
        :os_family,
        :runner_label,
        :architecture,
        :note,
        :citation
      )

      EngineOsEntry = Struct.new(
        :engine,
        :os_family,
        :support,
        :note,
        :citation
      )

      RUNNERS = begin
        entries = {}
        RUNNER_ROWS.each do |row|
          entry = RunnerEntry.new(*row)
          entry.freeze
          entries[entry.os_family] = entry
        end
        entries.freeze
      end

      ENGINE_OS = begin
        entries = {}
        ENGINE_OS_ROWS.each do |row|
          entry = EngineOsEntry.new(*row)
          entry.freeze
          entries[[entry.engine, entry.os_family]] = entry
        end
        entries.freeze
      end

      class << self
        # @param value [Object]
        # @return [Boolean] whether +value+ is a known CI OS family
        def os_family?(value)
          OS_FAMILIES.include?(value.to_s)
        end

        # @param os_family [String]
        # @return [RunnerEntry, nil]
        def runner_entry(os_family)
          RUNNERS[os_family.to_s]
        end

        # @param os_family [String]
        # @return [String, nil] the GitHub runner label for the OS family
        def runner_label(os_family)
          found = runner_entry(os_family)
          found && found.runner_label
        end

        # @param engine [String]
        # @param os_family [String]
        # @return [EngineOsEntry, nil]
        def engine_os_entry(engine, os_family)
          ENGINE_OS[[engine.to_s, os_family.to_s]]
        end

        # @param engine [String]
        # @param os_family [String]
        # @return [Boolean] whether the engine is supported on the OS family.
        #   An unknown pair is treated as unsupported rather than supported, so
        #   a missing claim can only hide CI coverage, never invent it.
        def engine_supports_os?(engine, os_family)
          found = engine_os_entry(engine, os_family)
          !found.nil? && found.support == "supported"
        end

        # @param engine [String]
        # @return [Array<String>] OS families the engine is supported on
        def supported_os_families(engine)
          ENGINE_OS.values
            .select { |entry| entry.engine == engine.to_s && entry.support == "supported" }
            .map { |entry| entry.os_family }
        end

        # @param os_family [String]
        # @return [Array<String>] engines supported on the OS family
        def supported_engines(os_family)
          ENGINE_OS.values
            .select { |entry| entry.os_family == os_family.to_s && entry.support == "supported" }
            .map { |entry| entry.engine }
        end
      end
    end
  end
end
