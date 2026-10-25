# frozen_string_literal: true

require "rubygems"
require "set"
require "kettle/rb/compat_matrix"

module Kettle
  module Rb
    # Converts between Ruby minor-version seams and the folder buckets used by
    # modular Gemfile matrices. A major-only bucket (rN) is the catch-all for
    # the newest range in that major; rN.M buckets cover the earlier range
    # ending at M.
    module RubySeriesBuckets
      module_function

      # Builds buckets and their Ruby ranges from the seam versions that define
      # the matrix. This is the shared implementation used by appraisal matrix
      # generation and by template curation.
      #
      # @param minor_versions [Array<String, Gem::Version>]
      # @return [Hash] bucket names and floor/ceiling ranges
      def from_minor_versions(minor_versions)
        by_major = Array(minor_versions).each_with_object({}) do |minor, grouped|
          version = Gem::Version.new(minor.to_s)
          major = version.segments[0]
          grouped[major] ||= []
          grouped[major] << version
        end

        buckets = []
        ranges = {}
        by_major.each do |major, versions|
          sorted = versions.uniq.sort
          sorted.each_with_index do |version, index|
            if index == sorted.length - 1
              bucket = "r#{major}"
              buckets << bucket
              ranges[bucket] = {:floor => version, :ceiling => Gem::Version.new("#{major}.99")}
              next
            end

            next_version = sorted[index + 1]
            upper = [next_version.segments[1].to_i - 1, version.segments[1].to_i].max
            bucket = "r#{major}.#{upper}"
            buckets << bucket
            ranges[bucket] = {
              :floor => version,
              :ceiling => Gem::Version.new("#{major}.#{upper}")
            }
          end
        end

        {:buckets => buckets.uniq, :bucket_ranges => ranges}
      end

      # Reconstructs the canonical ranges from the complete set of bucket
      # folder names. Named buckets are upper bounds; the major-only bucket
      # catches the remaining versions in that major.
      #
      # @param buckets [Array<String>] folder names such as r2.4, r2.6, r2
      # @return [Hash{String => Hash}] ranges keyed by bucket name
      def ranges_for_buckets(buckets)
        parsed = Array(buckets).map { |bucket|
          match = bucket.to_s.match(/\Ar(\d+)(?:\.(\d+))?\z/)
          [match[1].to_i, match[2] && match[2].to_i, bucket.to_s] if match
        }.compact
        parsed.group_by(&:first).each_with_object({}) do |(major, entries), result|
          named = entries.select { |_major, minor, _bucket| minor }.sort_by { |_major, minor, _bucket| minor }
          seams = [minimum_ruby_for_major(major)]
          named.each do |_entry_major, minor, _bucket|
            seams << Gem::Version.new("#{major}.#{minor + 1}")
          end
          seams.uniq!
          generated = from_minor_versions(seams)
          requested = entries.map(&:last).to_set
          generated.fetch(:bucket_ranges).each do |bucket, range|
            result[bucket] = range if requested.include?(bucket)
          end
        end
      end

      # Keeps every bucket whose Ruby range intersects the destination's
      # supported Ruby versions (all versions at or above +:minimum+).
      # Takes an options hash rather than a required keyword so the file parses
      # on every Ruby the gem supports.
      def relevant_buckets(buckets, options = {})
        floor = Gem::Version.new(options.fetch(:minimum).to_s)
        ranges = ranges_for_buckets(buckets)
        ranges.map { |bucket, range| bucket if range.fetch(:ceiling) >= floor }
          .compact
          .sort_by { |bucket| bucket_sort_key(bucket) }
      end

      def minimum_ruby_for_major(major)
        versions = CompatMatrix.entries.map { |key, _entry|
          match = key.match(/\Aruby-(\d+)\.(\d+)\z/)
          Gem::Version.new("#{match[1]}.#{match[2]}") if match && match[1].to_i == major
        }.compact
        versions.min || Gem::Version.new("#{major}.0")
      end
      private_class_method :minimum_ruby_for_major

      def bucket_sort_key(bucket)
        match = bucket.match(/\Ar(\d+)(?:\.(\d+))?\z/)
        [match[1].to_i, match[2] ? match[2].to_i : 999]
      end
      private_class_method :bucket_sort_key
    end
  end
end
