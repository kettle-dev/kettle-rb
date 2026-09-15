# frozen_string_literal: true

RSpec.describe Kettle::Rb::GemDependencies do
  it "records the sqlite3 requirement ActiveRecord declares in each series" do
    expect(described_class.requirements("activerecord", "5.2", "sqlite3")).to eq(["~> 1.3", ">= 1.3.6"])
    expect(described_class.requirements("activerecord", "7.0.8", "sqlite3")).to eq(["~> 1.4"])
    expect(described_class.requirements("activerecord", "7.1", "sqlite3")).to eq([">= 1.4"])
    expect(described_class.requirements(:activerecord, Gem::Version.new("8.1.0"), :sqlite3)).to eq([">= 2.1"])
  end

  it "cites the source of each requirement" do
    entry = described_class.entry("activerecord", "7.2", "sqlite3")

    expect(entry.source).to include("sqlite3_adapter.rb")
    expect(entry).to be_frozen
    expect(entry.requirements).to be_frozen
  end

  it "lists entries for a dependent and dependency pair, oldest series first" do
    series = described_class.entries_for("activerecord", "sqlite3").map(&:series)

    expect(series.first).to eq("5.2")
    expect(series.last).to eq("8.1")
  end

  it "returns nothing for unknown gems, series, and versions" do
    expect(described_class.entry("activerecord", "4.2", "sqlite3")).to be_nil
    expect(described_class.requirements("rake", "13.0", "sqlite3")).to be_empty
    expect(described_class.entry("activerecord", "8", "sqlite3")).to be_nil
    expect(described_class.entries_for("activerecord", "pg")).to be_empty
  end
end
