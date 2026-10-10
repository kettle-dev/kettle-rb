# frozen_string_literal: true

require "json"
require "net/http"
require "ripper"
require "tmpdir"
require "kettle/rb/platform_support/generator"

RSpec.describe Kettle::Rb::PlatformSupport::Generator do
  subject(:generator) do
    described_class.new(
      :truffleruby_releases_fetcher => lambda { truffleruby_releases },
      :windows_versions_fetcher => lambda { windows_versions },
      :generated_on => "2026-10-09"
    )
  end

  let(:truffleruby_releases) do
    [
      {"tag_name" => "graal-34.0.0", "assets" => [
        {"name" => "truffleruby-34.0.0-linux-amd64.tar.gz"},
        {"name" => "truffleruby-34.0.0-linux-aarch64.tar.gz"},
        {"name" => "truffleruby-34.0.0-macos-aarch64.tar.gz"}
      ]},
      {"tag_name" => "graal-33.0.0", "assets" => [
        {"name" => "truffleruby-33.0.0-linux-amd64.tar.gz"},
        {"name" => "truffleruby-33.0.0-macos-amd64.tar.gz"},
        {"name" => "truffleruby-33.0.0-macos-aarch64.tar.gz"}
      ]}
    ]
  end

  let(:windows_versions) do
    {
      "3.3.10" => {"x64" => "https://example.test/rubyinstaller-3.3.10-x64.7z"},
      "3.4.1" => {"x64" => "https://example.test/rubyinstaller-3.4.1-x64.7z", "arm64" => "https://example.test/rubyinstaller-3.4.1-arm.7z"},
      "4.0.7" => {"x64" => "https://example.test/rubyinstaller-4.0.7-x64.7z", "arm64" => "https://example.test/rubyinstaller-4.0.7-arm.7z"},
      "head" => {"x64" => "https://example.test/rubyinstaller-head-x64.7z"},
      "ucrt" => {"x64" => "https://example.test/rubyinstaller-ucrt-x64.7z"}
    }
  end

  it "derives TruffleRuby Windows support from the release scan" do
    expect(generator.truffleruby_releases_scanned).to eq(2)
    expect(generator.truffleruby_windows_asset_count).to eq(0)
    expect(generator.truffleruby_windows_support).to eq("unsupported")
  end

  it "flips TruffleRuby Windows support when a Windows asset appears" do
    releases = truffleruby_releases + [
      {"tag_name" => "graal-99.0.0", "assets" => [{"name" => "truffleruby-99.0.0-windows-amd64.zip"}]}
    ]
    future = described_class.new(
      :truffleruby_releases_fetcher => lambda { releases },
      :windows_versions_fetcher => lambda { windows_versions },
      :generated_on => "2026-10-09"
    )

    expect(future.truffleruby_windows_asset_count).to eq(1)
    expect(future.truffleruby_windows_support).to eq("supported")
    row = future.engine_os_rows.last
    expect(row[0, 3]).to eq(["truffleruby", "windows", "supported"])
  end

  it "flags mingw, mswin, and installer archive names as Windows assets" do
    releases = [
      {"tag_name" => "x", "assets" => [{"name" => "ruby-3.4.1-x64-mingw-ucrt.7z"}]},
      {"tag_name" => "y", "assets" => [{"name" => "rubyinstaller-3.4.1-2-x64.exe"}]}
    ]
    probe = described_class.new(
      :truffleruby_releases_fetcher => lambda { releases },
      :windows_versions_fetcher => lambda { windows_versions }
    )

    expect(probe.truffleruby_windows_asset_count).to eq(2)
  end

  it "derives RubyInstaller series, ignoring non-version keys" do
    expect(generator.rubyinstaller_series).to eq(["3.3", "3.4", "4.0"])
    expect(generator.rubyinstaller_arm64_series).to eq(["3.4", "4.0"])
  end

  it "appends the derived TruffleRuby Windows row after the curated rows" do
    rows = generator.engine_os_rows

    expect(rows.length).to eq(described_class::ENGINE_OS_ROWS.length + 1)
    expect(rows.last[0, 3]).to eq(["truffleruby", "windows", "unsupported"])
    expect(rows.last[3]).to include("2 releases scanned 2026-10-09")
    expect(rows.map { |row| row[0, 2] }).to include(["truffleruby", "macos"], ["jruby", "windows"])
  end

  it "renders a loadable data file with provenance" do
    source = generator.render

    expect(Ripper.sexp(source)).not_to be_nil
    expect(source).to include('GENERATED_ON = "2026-10-09"')
    expect(source).to include("TRUFFLERUBY_RELEASES_SCANNED = 2")
    expect(source).to include('RUBYINSTALLER_SERIES = ["3.3", "3.4", "4.0"].freeze')
    expect(source).to include('RUBYINSTALLER_ARM64_SERIES = ["3.4", "4.0"].freeze')
    expect(source).to include('["truffleruby", "windows", "unsupported", "Never shipped a Windows build (zero Windows assets across 2 releases scanned 2026-10-09); setup-ruby hard-fails"')
  end

  it "writes the rendered data file" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "data.rb")

      expect(generator.write(path)).to eq(path)
      expect(File.read(path)).to eq(generator.render)
    end
  end

  it "fetches TruffleRuby releases and windows-versions.json by default" do
    response = instance_double(Net::HTTPResponse, :body => JSON.generate(truffleruby_releases))
    request = nil
    allow(Net::HTTP).to receive(:start) do |_host, _port, *_args, &block|
      http = double("http")
      allow(http).to receive(:request) do |req|
        request = req
        response
      end
      block.call(http)
    end
    allow(Net::HTTP).to receive(:get).and_return(JSON.generate(windows_versions))

    default = described_class.new(:generated_on => "2026-10-09")

    expect(default.truffleruby_windows_support).to eq("unsupported")
    expect(default.rubyinstaller_series).to eq(["3.3", "3.4", "4.0"])
    expect(request["User-Agent"]).to eq(described_class::USER_AGENT)
    expect(Net::HTTP).to have_received(:get).with(URI.parse(described_class::WINDOWS_VERSIONS_URL))
  end
end
