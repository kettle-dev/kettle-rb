# frozen_string_literal: true

RSpec.describe Kettle::Rb::GemFloors do
  it "tracks the ActiveRecord family and sqlite3" do
    expect(described_class::TRACKED_GEMS).to include("activemodel", "activerecord", "activesupport", "sqlite3")
    expect(described_class.tracked?("activerecord")).to be(true)
    expect(described_class.tracked?(:sqlite3)).to be(true)
    expect(described_class.tracked?("rake")).to be(false)
  end

  it "exposes one frozen entry per tracked minor series" do
    entry = described_class.entry("activerecord", "7.1.3")

    expect(entry.series).to eq("7.1")
    expect(entry).to be_frozen
    expect(entry.unpatched_advisories).to be_frozen
    expect(described_class.entries_for("activerecord").map(&:series)).to include("5.2", "7.1", "8.1")
  end

  it "floors a series at or above the patched version of its advisories" do
    expect(Gem::Version.new(described_class.floor("activerecord", "7.1"))).to be >= Gem::Version.new("7.1.5.2")
    expect(Gem::Version.new(described_class.floor("activerecord", "7.2"))).to be >= Gem::Version.new("7.2.2.2")
    expect(Gem::Version.new(described_class.floor("sqlite3", "2.9"))).to be >= Gem::Version.new("2.9.5")
  end

  it "builds series-pinned requirements that include the security floor" do
    floor = described_class.floor("activerecord", Gem::Version.new("7.1.0"))

    expect(described_class.requirements("activerecord", "7.1")).to eq(["~> 7.1.0", ">= #{floor}"])
  end

  it "records advisories that have no fix within a series" do
    expect(described_class.unpatched_advisories("activerecord", "7.0")).to include("CVE-2025-55193")
    expect(described_class.entry("activerecord", "7.1").patched_advisories).to include("CVE-2025-55193")
    expect(described_class.unpatched_advisories("activerecord", "7.1")).not_to include("CVE-2025-55193")
  end

  it "returns nothing for untracked gems, unknown series, and unusable versions" do
    expect(described_class.entry("rake", "13.0")).to be_nil
    expect(described_class.floor("activerecord", "1.0")).to be_nil
    expect(described_class.requirements("activerecord", "1.0")).to be_empty
    expect(described_class.unpatched_advisories("activerecord", "1.0")).to be_empty
    expect(described_class.entry("activerecord", "8")).to be_nil
    expect(described_class.series_for("not a version")).to be_nil
  end

  it "records when the data was generated" do
    expect(described_class::GENERATED_ON).to match(/\A\d{4}-\d{2}-\d{2}\z/)
  end
end
