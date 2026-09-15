# frozen_string_literal: true

require "json"
require "net/http"
require "ripper"
require "tmpdir"
require "kettle/rb/gem_floors/generator"

RSpec.describe Kettle::Rb::GemFloors::Generator do
  subject(:generator) do
    described_class.new(
      :tracked => [["widget", "1.0"], ["gadget", "3.0"]],
      :versions_fetcher => lambda { |name| versions.fetch(name) },
      :advisories_fetcher => lambda { |name| advisories.fetch(name) },
      :advisory_db_commit => "abc123",
      :generated_on => "2026-09-14"
    )
  end

  let(:advisory_class) do
    Class.new do
      attr_reader :id

      def initialize(id, patched)
        @id = id
        @patched = patched
      end

      def vulnerable?(version)
        @patched.none? { |requirement| Gem::Requirement.new(*requirement.split(/\s*,\s*/)).satisfied_by?(version) }
      end
    end
  end

  let(:versions) do
    {
      "widget" => [
        release("0.9.0", ">= 1.9"),
        release("1.0.0", ">= 2.0"),
        release("1.0.1", ">= 2.0"),
        release("1.0.2", ">= 2.0"),
        release("1.1.0", ">= 2.4"),
        release("1.1.1", ">= 2.4"),
        release("1.1.2", ">= 3.0"),
        release("2.0.0", ">= 3.0"),
        release("2.0.1.rc1", ">= 3.0", "prerelease" => true),
        release("2.0.2", ">= 3.0", "platform" => "java"),
        release("3", ">= 3.0")
      ],
      "gadget" => [
        release("3.0.0", nil, "platform" => nil),
        release("3.0.1", "")
      ]
    }
  end

  let(:advisories) do
    {
      "widget" => [
        advisory_class.new("CVE-2099-0001", ["~> 1.0.2", ">= 2.0.0"]),
        advisory_class.new("GHSA-aaaa-bbbb-cccc", [">= 9.0"])
      ],
      "gadget" => [advisory_class.new("CVE-2099-0002", ["= 3.0.0"])]
    }
  end

  def release(number, ruby, extra = {})
    {"number" => number, "ruby_version" => ruby, "platform" => "ruby", "prerelease" => false}.merge(extra)
  end

  it "floors each series at its newest patch and records fixed and unfixed advisories" do
    expect(generator.rows).to eq([
      ["widget", "1.0", "1.0.2", ">= 2.0", ["CVE-2099-0001"], ["GHSA-aaaa-bbbb-cccc"]],
      ["widget", "1.1", "1.1.1", ">= 2.4", [], ["CVE-2099-0001", "GHSA-aaaa-bbbb-cccc"]],
      ["widget", "2.0", "2.0.0", ">= 3.0", [], ["GHSA-aaaa-bbbb-cccc"]],
      ["gadget", "3.0", "3.0.0", nil, ["CVE-2099-0002"], []]
    ])
  end

  it "keeps the series' original minimum Ruby instead of a patch that raises it" do
    widget_1_1 = generator.rows.find { |row| row[0] == "widget" && row[1] == "1.1" }

    expect(widget_1_1[2]).to eq("1.1.1")
  end

  it "prefers the newest unaffected patch over a newer affected one" do
    gadget = generator.rows.find { |row| row[0] == "gadget" }

    expect(gadget[2]).to eq("3.0.0")
    expect(gadget[5]).to be_empty
  end

  it "treats an unparseable Ruby requirement as having no minimum" do
    versions["gadget"] = [release("3.0.0", "banana"), release("3.0.1", ">= 2.0")]

    expect(generator.rows.find { |row| row[0] == "gadget" }[2]).to eq("3.0.0")
  end

  it "renders a loadable data file with provenance" do
    source = generator.render

    expect(Ripper.sexp(source)).not_to be_nil
    expect(source).to include('GENERATED_ON = "2026-09-14"')
    expect(source).to include('ADVISORY_DB_COMMIT = "abc123"')
    expect(source).to include('TRACKED_GEMS = ["widget", "gadget"].freeze')
    expect(source).to include('["widget", "1.0", "1.0.2", ">= 2.0", ["CVE-2099-0001"], ["GHSA-aaaa-bbbb-cccc"]],')
  end

  it "writes the rendered data file" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "data.rb")

      expect(generator.write(path)).to eq(path)
      expect(File.read(path)).to eq(generator.render)
    end
  end

  it "fetches rubygems.org versions and bundler-audit advisories by default" do
    require "bundler/audit/database"
    database = double("database", :commit_id => "0123456789abcdef", :advisories_for => [])
    allow(Bundler::Audit::Database).to receive(:new).and_return(database)
    allow(Net::HTTP).to receive(:get).and_return(JSON.generate([release("1.0.0", ">= 2.0")]))

    default = described_class.new(:tracked => [["widget", "1.0"]], :generated_on => "2026-09-14")

    expect(default.advisory_db_commit).to eq("0123456789ab")
    expect(default.rows).to eq([["widget", "1.0", "1.0.0", ">= 2.0", [], []]])
    expect(Net::HTTP).to have_received(:get).with(URI.parse("https://rubygems.org/api/v1/versions/widget.json"))
    expect(database).to have_received(:advisories_for).with("widget")
  end

  it "records no advisory database commit when the database has none" do
    require "bundler/audit/database"
    allow(Bundler::Audit::Database).to receive(:new).and_return(double("database", :commit_id => nil))

    expect(described_class.new(:tracked => []).advisory_db_commit).to be_nil
  end

  it "defaults to the tracked gem list and today's date" do
    require "bundler/audit/database"
    allow(Bundler::Audit::Database).to receive(:new).and_return(double("database", :commit_id => nil))

    default = described_class.new

    expect(default.tracked).to eq(described_class::TRACKED)
    expect(default.generated_on).to match(/\A\d{4}-\d{2}-\d{2}\z/)
  end
end
