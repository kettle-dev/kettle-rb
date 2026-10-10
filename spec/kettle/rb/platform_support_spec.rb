# frozen_string_literal: true

RSpec.describe Kettle::Rb::PlatformSupport do
  it "names the three CI OS families in matrix order" do
    expect(described_class::OS_FAMILIES).to eq(%w[linux macos windows])
    expect(described_class.os_family?("macos")).to be(true)
    expect(described_class.os_family?(:windows)).to be(true)
    expect(described_class.os_family?("x86_64-linux")).to be(false)
    expect(described_class.os_family?("ubuntu-latest")).to be(false)
  end

  it "maps each OS family to exactly one frozen runner entry with a citation" do
    expect(described_class.runner_label("linux")).to eq("ubuntu-latest")
    expect(described_class.runner_label("macos")).to eq("macos-latest")
    expect(described_class.runner_label("windows")).to eq("windows-latest")
    expect(described_class.runner_label("plan9")).to be_nil

    entry = described_class.runner_entry("macos")
    expect(entry).to be_frozen
    expect(entry.architecture).to eq("arm64")
    expect(entry.citation).to start_with("https://")
  end

  it "supports every engine on linux and macos, and only MRI and JRuby on windows" do
    %w[ruby jruby truffleruby].each do |engine|
      expect(described_class.engine_supports_os?(engine, "linux")).to be(true), "expected #{engine}/linux"
      expect(described_class.engine_supports_os?(engine, "macos")).to be(true), "expected #{engine}/macos"
    end
    expect(described_class.engine_supports_os?("ruby", "windows")).to be(true)
    expect(described_class.engine_supports_os?("jruby", "windows")).to be(true)
    expect(described_class.engine_supports_os?("truffleruby", "windows")).to be(false)
  end

  it "evidences the TruffleRuby Windows exclusion with a citation and a release count" do
    entry = described_class.engine_os_entry("truffleruby", "windows")

    expect(entry.support).to eq("unsupported")
    expect(entry.citation).to start_with("https://")
    expect(entry.note).to include(described_class::TRUFFLERUBY_RELEASES_SCANNED.to_s)
    expect(described_class::TRUFFLERUBY_RELEASES_SCANNED).to be > 0
  end

  it "treats unknown engine/OS pairs as unsupported so a missing claim cannot invent coverage" do
    expect(described_class.engine_supports_os?("mruby", "linux")).to be(false)
    expect(described_class.engine_supports_os?("ruby", "plan9")).to be(false)
    expect(described_class.engine_os_entry("mruby", "linux")).to be_nil
  end

  it "enumerates supported families per engine and engines per family" do
    expect(described_class.supported_os_families("truffleruby")).to contain_exactly("linux", "macos")
    expect(described_class.supported_os_families("ruby")).to contain_exactly("linux", "macos", "windows")
    expect(described_class.supported_engines("windows")).to contain_exactly("ruby", "jruby")
  end

  it "records generation provenance and derived RubyInstaller series" do
    expect(described_class::GENERATED_ON).to match(/\A\d{4}-\d{2}-\d{2}\z/)
    expect(described_class::RUBYINSTALLER_SERIES).to include("3.3", "3.4", "4.0")
    expect(described_class::RUBYINSTALLER_ARM64_SERIES).to include("3.4", "4.0")
    expect(described_class::RUBYINSTALLER_ARM64_SERIES).not_to include("3.3")
  end
end
