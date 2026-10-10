# frozen_string_literal: true

require "rubygems"

module Kettle
  module Rb
    module PlatformSupport
      # Regenerates +lib/kettle/rb/platform_support/data.rb+ from the GitHub
      # releases API (TruffleRuby) and ruby/setup-ruby's windows-versions.json.
      #
      # This is development tooling. It is loaded by the
      # +kettle:rb:platform_support:generate+ rake task, never by
      # +require "kettle/rb"+.
      #
      # Two claims are re-derived from the network on every run, because they
      # are the ones generation depends on and they can change:
      #
      # - TruffleRuby Windows support: derived by scanning every TruffleRuby
      #   release for Windows assets. Zero assets means "unsupported", and a
      #   future TruffleRuby Windows build flips the row on regeneration.
      # - The RubyInstaller series available on Windows, recorded as
      #   +RUBYINSTALLER_SERIES+ provenance for the ruby/windows claim.
      #
      # Every other claim is documentation-sourced and curated below with its
      # citation, so an unevidenced claim cannot be expressed in the data file.
      class Generator
        TRUFFLERUBY_RELEASES_URL = "https://api.github.com/repos/truffleruby/truffleruby/releases?per_page=100"
        WINDOWS_VERSIONS_URL = "https://raw.githubusercontent.com/ruby/setup-ruby/master/windows-versions.json"
        USER_AGENT = "kettle-rb platform-support generator"
        DATA_PATH = File.expand_path(File.join(File.dirname(__FILE__), "data.rb"))

        # TruffleRuby assets are named e.g. +truffleruby-24.2.0-linux-amd64.tar.gz+;
        # a Windows build would carry one of these tokens.
        WINDOWS_ASSET_PATTERN = /windows|mingw|mswin|\.exe\z|\.msi\z/i.freeze

        TRUFFLERUBY_WINDOWS_CITATION = "https://github.com/ruby/setup-ruby/blob/master/README.md"

        # CI OS families: a fourth platform vocabulary, distinct from Gemfile DSL
        # platform symbols (Ruby implementations), Gem::Platform strings
        # (OS/architecture), and GitHub runner labels (CI hardware). These values
        # select runner labels; they must never reach +bundle lock --add-platform+
        # or a Gemfile +platforms:+ DSL untranslated.
        OS_FAMILIES = ["linux", "macos", "windows"].freeze

        # Documentation-sourced runner claims:
        # [os_family, runner_label, architecture, note, citation]
        RUNNER_ROWS = [
          ["linux", "ubuntu-latest", "x86_64",
            "ARM64 lanes available via ubuntu-22.04-arm / ubuntu-24.04-arm / ubuntu-26.04-arm, free for public repos",
            "https://github.blog/changelog/2025-08-07-arm64-hosted-runners-for-public-repositories-are-now-generally-available/"],
          ["macos", "macos-latest", "arm64",
            "Floating label; became ARM64 during the Apr-May 2024 macOS 14 migration and resolves to macOS 26 ARM64 since 2026-07-15",
            "https://github.com/actions/runner-images/issues/14167"],
          ["windows", "windows-latest", "x64",
            "x64 only (Server 2025); ARM64 Windows requires the explicit windows-11-arm label",
            "https://github.blog/changelog/2025-08-07-arm64-hosted-runners-for-public-repositories-are-now-generally-available/"]
        ].freeze

        # Documentation-sourced engine support claims:
        # [engine, os_family, support, note, citation]
        # The truffleruby/windows row is deliberately absent: it is derived from
        # the releases scan, not curated.
        ENGINE_OS_ROWS = [
          ["ruby", "linux", "supported",
            "All versioned MRI workflows run on Linux; aarch64-linux prebuilts ship in the ruby-builder toolcache from 2.3.5",
            "https://github.com/ruby/ruby-builder/releases/tag/toolcache"],
          ["ruby", "macos", "supported",
            "macos-latest is ARM64; community prebuilts from 2.6.7 and native arm64-darwin configure.ac support from 2.7.2",
            "https://github.com/ruby/ruby/commit/23655e6de5ee989feb8c65c7061fe9a71579dc54"],
          ["ruby", "windows", "supported",
            "RubyInstaller x64 since 2.0.0; ARM64 builds recorded in RUBYINSTALLER_ARM64_SERIES (from 3.4); supported series in RUBYINSTALLER_SERIES",
            "https://github.com/ruby/setup-ruby/blob/master/windows-versions.json"],
          ["jruby", "linux", "supported",
            "Official, including aarch64-Linux jffi from 9.1",
            "https://www.jruby.org/2021-09-22/jruby-9-3-0-0.html"],
          ["jruby", "macos", "supported",
            "Official from 9.3; arm64 jffi slice binary-verified from 9.2.18.0; requires an aarch64 JDK (Temurin 11+ or Zulu 8)",
            "https://github.com/jruby/jruby/releases/tag/9.2.18.0"],
          ["jruby", "windows", "supported",
            "Official; CRuby C extensions cannot be built or used, so gems must be pure-Ruby or ship Java extensions",
            "https://www.jruby.org/2021-09-22/jruby-9-3-0-0.html"],
          ["truffleruby", "linux", "supported",
            "Official; linux-aarch64 since 21.2",
            "https://github.com/truffleruby/truffleruby/releases"],
          ["truffleruby", "macos", "supported",
            "darwin-aarch64 since 22.2.0; macOS Intel removed in 34.0, so macos-*-intel lanes must exclude TruffleRuby 34+",
            "https://github.com/truffleruby/truffleruby/releases/tag/graal-34.0.0"]
        ].freeze

        # @return [String] generation date recorded in the data file
        attr_reader :generated_on

        # @param options [Hash]
        # @option options [#call] :truffleruby_releases_fetcher returns GitHub release hashes
        # @option options [#call] :windows_versions_fetcher returns the parsed windows-versions.json
        # @option options [String] :generated_on date to record
        def initialize(options = {})
          @truffleruby_releases_fetcher = options[:truffleruby_releases_fetcher] || method(:fetch_truffleruby_releases)
          @windows_versions_fetcher = options[:windows_versions_fetcher] || method(:fetch_windows_versions)
          @generated_on = options[:generated_on] || Time.now.utc.strftime("%Y-%m-%d")
        end

        # @return [Integer] TruffleRuby releases examined for Windows assets
        def truffleruby_releases_scanned
          truffleruby_releases.length
        end

        # @return [Integer] Windows assets found across all TruffleRuby releases
        def truffleruby_windows_asset_count
          truffleruby_releases.inject(0) do |count, release|
            count + windows_asset_names(release).length
          end
        end

        # @return [String] "supported" or "unsupported", derived from the scan
        def truffleruby_windows_support
          truffleruby_windows_asset_count.zero? ? "unsupported" : "supported"
        end

        # @return [Array<String>] minor series setup-ruby can install on Windows
        def rubyinstaller_series
          series_matching { true }
        end

        # @return [Array<String>] minor series with an ARM64 RubyInstaller build,
        #   derived from the arch keys rather than curated
        def rubyinstaller_arm64_series
          versions = windows_versions
          series_matching do |key|
            archs = versions[key]
            archs.is_a?(Hash) && archs.key?("arm64")
          end
        end

        # @return [Array<Array>] engine support rows, curated rows plus the
        #   derived truffleruby/windows row
        def engine_os_rows
          ENGINE_OS_ROWS.map(&:dup) << truffleruby_windows_row
        end

        # @return [String] Ruby source for +data.rb+
        def render
          lines = [
            "# frozen_string_literal: true",
            "",
            "# Generated by `rake kettle:rb:platform_support:generate`; do not edit by hand.",
            "# Sources: GitHub releases API (TruffleRuby), ruby/setup-ruby windows-versions.json,",
            "# and the documentation citation carried on each row.",
            "",
            "module Kettle",
            "  module Rb",
            "    module PlatformSupport",
            "      GENERATED_ON = #{generated_on.inspect}",
            "      TRUFFLERUBY_RELEASES_SCANNED = #{truffleruby_releases_scanned.inspect}",
            "      RUBYINSTALLER_SERIES = #{rubyinstaller_series.inspect}.freeze",
            "      RUBYINSTALLER_ARM64_SERIES = #{rubyinstaller_arm64_series.inspect}.freeze",
            "      OS_FAMILIES = #{OS_FAMILIES.inspect}.freeze",
            "      RUNNER_ROWS = [",
            RUNNER_ROWS.map { |row| "        #{row.inspect}" }.join(",\n"),
            "      ].freeze",
            "      ENGINE_OS_ROWS = [",
            engine_os_rows.map { |row| "        #{row.inspect}" }.join(",\n"),
            "      ].freeze",
            "    end",
            "  end",
            "end",
            ""
          ]
          lines.join("\n")
        end

        # Writes the rendered data file.
        #
        # @param path [String]
        # @return [String] the written path
        def write(path = DATA_PATH)
          File.open(path, "w") { |file| file.write(render) }
          path
        end

        private

        def truffleruby_releases
          @truffleruby_releases ||= @truffleruby_releases_fetcher.call
        end

        def windows_versions
          @windows_versions ||= @windows_versions_fetcher.call
        end

        def series_matching(&block)
          windows_versions.keys
            .select { |key| key.to_s =~ /\A\d+\.\d+\.\d+\z/ && block.call(key) }
            .map { |key| key.to_s[/\A\d+\.\d+/] }
            .uniq
            .sort_by { |series| Gem::Version.new(series) }
        end

        def windows_asset_names(release)
          (release["assets"] || []).map { |asset| asset["name"].to_s }.select do |name|
            name =~ WINDOWS_ASSET_PATTERN
          end
        end

        def truffleruby_windows_row
          scanned = truffleruby_releases_scanned
          count = truffleruby_windows_asset_count
          if count.zero?
            ["truffleruby", "windows", "unsupported",
              "Never shipped a Windows build (zero Windows assets across #{scanned} releases scanned #{generated_on}); setup-ruby hard-fails",
              TRUFFLERUBY_WINDOWS_CITATION]
          else
            ["truffleruby", "windows", "supported",
              "#{count} Windows assets across #{scanned} releases scanned #{generated_on}",
              TRUFFLERUBY_WINDOWS_CITATION]
          end
        end

        def fetch_truffleruby_releases
          require "json"
          require "net/http"
          require "uri"

          uri = URI.parse(TRUFFLERUBY_RELEASES_URL)
          response = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
            request = Net::HTTP::Get.new(uri.request_uri)
            request["Accept"] = "application/vnd.github+json"
            request["User-Agent"] = USER_AGENT
            http.request(request)
          end
          JSON.parse(response.body)
        end

        def fetch_windows_versions
          require "json"
          require "net/http"
          require "uri"

          JSON.parse(Net::HTTP.get(URI.parse(WINDOWS_VERSIONS_URL)))
        end
      end
    end
  end
end
