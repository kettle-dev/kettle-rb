# frozen_string_literal: true

require "rubygems"

module Kettle
  module Rb
    # Curated runtime requirements that a tracked gem places on another tracked
    # gem, per minor series.
    #
    # Each requirement is copied from the dependent gem's own source at the
    # series' newest patch (the patch {GemFloors} uses as the security floor), so
    # consumers that apply those floors also get the matching requirement.
    module GemDependencies
      Entry = Struct.new(:gem_name, :series, :dependency, :requirements, :source)

      ACTIVERECORD_SQLITE3_ADAPTER = "activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb"

      ROWS = [
        ["activerecord", "5.2", "sqlite3", ["~> 1.3", ">= 1.3.6"], "rails v5.2.8.1 #{ACTIVERECORD_SQLITE3_ADAPTER}"],
        ["activerecord", "6.0", "sqlite3", ["~> 1.4"], "rails v6.0.6.1 #{ACTIVERECORD_SQLITE3_ADAPTER}"],
        ["activerecord", "6.1", "sqlite3", ["~> 1.4"], "rails v6.1.7.10 #{ACTIVERECORD_SQLITE3_ADAPTER}"],
        ["activerecord", "7.0", "sqlite3", ["~> 1.4"], "rails v7.0.10 #{ACTIVERECORD_SQLITE3_ADAPTER}"],
        ["activerecord", "7.1", "sqlite3", [">= 1.4"], "rails v7.1.6 #{ACTIVERECORD_SQLITE3_ADAPTER}"],
        ["activerecord", "7.2", "sqlite3", [">= 1.4"], "rails v7.2.3.2 #{ACTIVERECORD_SQLITE3_ADAPTER}"],
        ["activerecord", "8.0", "sqlite3", [">= 2.1"], "rails v8.0.5.1 #{ACTIVERECORD_SQLITE3_ADAPTER}"],
        ["activerecord", "8.1", "sqlite3", [">= 2.1"], "rails v8.1.3.1 #{ACTIVERECORD_SQLITE3_ADAPTER}"]
      ].freeze

      ENTRIES = begin
        entries = {}
        ROWS.each do |row|
          entry = Entry.new(*row)
          entry.requirements.freeze
          entry.freeze
          entries[[entry.gem_name, entry.series, entry.dependency]] = entry
        end
        entries.freeze
      end

      class << self
        # @param gem_name [String] the dependent gem, e.g. "activerecord"
        # @param version [String, Gem::Version] any version within the series
        # @param dependency [String] the required gem, e.g. "sqlite3"
        # @return [Entry, nil]
        def entry(gem_name, version, dependency)
          series = GemFloors.series_for(version)
          series && ENTRIES[[gem_name.to_s, series, dependency.to_s]]
        end

        # @return [Array<String>] requirements +gem_name+ places on +dependency+; empty when unknown
        def requirements(gem_name, version, dependency)
          found = entry(gem_name, version, dependency)
          found ? found.requirements : []
        end

        # @return [Array<Entry>] entries for a dependent/dependency pair, oldest series first
        def entries_for(gem_name, dependency)
          ENTRIES.values
            .select { |entry| entry.gem_name == gem_name.to_s && entry.dependency == dependency.to_s }
            .sort_by { |entry| Gem::Version.new(entry.series) }
        end
      end
    end
  end
end
