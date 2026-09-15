# frozen_string_literal: true

require "rubygems"
require_relative "gem_floors/data"

module Kettle
  module Rb
    # Security floors for tracked gems, one entry per minor series.
    #
    # For each series the floor is the newest released patch that keeps the
    # series' original minimum Ruby, never below an advisory's patched version.
    # Advisories that still affect the floor (a series with no fixed release)
    # are recorded as unpatched so consumers can decide how to treat it.
    #
    # The data lives in +gem_floors/data.rb+ and is regenerated from the
    # rubygems.org versions API and ruby-advisory-db by
    # +rake kettle:rb:gem_floors:generate+ (see {GemFloors::Generator}).
    module GemFloors
      Entry = Struct.new(
        :gem_name,
        :series,
        :floor,
        :ruby,
        :patched_advisories,
        :unpatched_advisories
      )

      ENTRIES = begin
        entries = {}
        ROWS.each do |row|
          entry = Entry.new(*row)
          entry.patched_advisories.freeze
          entry.unpatched_advisories.freeze
          entry.freeze
          entries[[entry.gem_name, entry.series]] = entry
        end
        entries.freeze
      end

      class << self
        # @param gem_name [String]
        # @return [Boolean] whether floors are tracked for +gem_name+
        def tracked?(gem_name)
          TRACKED_GEMS.include?(gem_name.to_s)
        end

        # @param gem_name [String]
        # @param version [String, Gem::Version] any version within the series, e.g. "7.1" or "7.1.3"
        # @return [Entry, nil]
        def entry(gem_name, version)
          series = series_for(version)
          series && ENTRIES[[gem_name.to_s, series]]
        end

        # @param gem_name [String]
        # @return [Array<Entry>] entries for +gem_name+, oldest series first
        def entries_for(gem_name)
          ENTRIES.values
            .select { |entry| entry.gem_name == gem_name.to_s }
            .sort_by { |entry| Gem::Version.new(entry.series) }
        end

        # @return [String, nil] the security floor for the series containing +version+
        def floor(gem_name, version)
          found = entry(gem_name, version)
          found && found.floor
        end

        # Requirements that pin the series and enforce its floor.
        #
        # @example
        #   Kettle::Rb::GemFloors.requirements("activerecord", "7.1") #=> ["~> 7.1.0", ">= 7.1.6"]
        # @return [Array<String>] empty when the series is not tracked
        def requirements(gem_name, version)
          found = entry(gem_name, version)
          return [] unless found

          ["~> #{found.series}.0", ">= #{found.floor}"]
        end

        # @return [Array<String>] advisory identifiers still affecting the series' floor
        def unpatched_advisories(gem_name, version)
          found = entry(gem_name, version)
          found ? found.unpatched_advisories : []
        end

        # @param version [String, Gem::Version]
        # @return [String, nil] the "major.minor" series, or nil when it cannot be determined
        def series_for(version)
          segments = Gem::Version.new(version.to_s).segments
          return nil if segments.size < 2

          "#{segments[0]}.#{segments[1]}"
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
