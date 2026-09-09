# frozen_string_literal: true

RSpec.describe Kettle::Rb do
  it "has a version number" do
    expect(Kettle::Rb::VERSION).not_to be_nil
  end

  it "exposes the Ruby compatibility matrix" do
    matrix = Kettle::Rb::CompatMatrix

    expect(matrix.entries).to include("ruby-1.8", "ruby-3.4", "jruby-10.0", "jruby-10.1")
    expect(matrix.entry("jruby-10.0").ruby).to eq("jruby-10.0.0.0")
    expect(matrix.entry("jruby-10.1").ruby).to eq("jruby-10.1.0.0")
    expect(matrix.entry("jruby-10.1").mri).to eq("3.4")
    expect(matrix.workflow_ruby_floor("jruby-10.1")).to eq("3.4")
    expect(matrix.entry("truffleruby-34.0").ruby).to eq("truffleruby-34.0.1")
    expect(matrix.workflow_ruby_floor("truffleruby-23.1")).to eq("3.1")
    expect(matrix.engine_workflow("truffle")).to eq("truffleruby")
  end

  it "selects RuboCop LTS data from the matrix" do
    matrix = Kettle::Rb::CompatMatrix

    expect(matrix.rubocop_template_tokens(Gem::Version.new("2.4"))).to eq([
      "\"~> 12.3\", \">= 12.3.3\"",
      "rubocop-ruby2_4",
      "\"~> 3.0\", \">= 3.0.7\""
    ])
    expect(matrix.rubocop_lts_branch_for_gem("rubocop-ruby3_2")).to eq("r3_2-even-v24")
    expect(matrix.rubocop_ruby_gem?("rubocop-ruby3_2")).to be(true)
    expect(matrix.rubocop_ruby_gem?("rubocop-lts")).to be(false)
    expect(matrix.rubocop_lts_branch_by_gem).to include(
      "rubocop-ruby1_8" => "r1_8-even-v0",
      "rubocop-ruby3_2" => "r3_2-even-v24"
    )
  end

  it "selects the oldest RuboCop LTS data when minimum Ruby is absent or invalid" do
    matrix = Kettle::Rb::CompatMatrix

    oldest_tokens = [
      "\"~> 0.3\", \">= 0.3.3\"",
      "rubocop-ruby1_8",
      "\"~> 2.0\", \">= 2.0.7\""
    ]

    expect(matrix.rubocop_template_tokens(nil)).to eq(oldest_tokens)
    expect(matrix.rubocop_template_tokens("")).to eq(oldest_tokens)
    expect(matrix.rubocop_template_tokens("not-a-version")).to eq(oldest_tokens)
  end

  it "accepts Gem::Version minimum Ruby inputs" do
    matrix = Kettle::Rb::CompatMatrix

    expect(matrix.rubocop_template_tokens(Gem::Version.new("3.2"))).to eq([
      "\"~> 24.2\", \">= 24.2.3\"",
      "rubocop-ruby3_2",
      "\"~> 3.0\", \">= 3.0.8\""
    ])
  end

  it "uses the released RuboCop LTS floors for every supported Ruby branch" do
    matrix = Kettle::Rb::CompatMatrix
    expected_floors = {
      "1.8" => ["0.3.3", "rubocop-ruby1_8", "2.0.7"],
      "1.9" => ["2.3.3", "rubocop-ruby1_9", "3.0.7"],
      "2.0" => ["4.3.4", "rubocop-ruby2_0", "3.0.7"],
      "2.1" => ["6.3.3", "rubocop-ruby2_1", "3.0.7"],
      "2.2" => ["8.3.3", "rubocop-ruby2_2", "3.0.7"],
      "2.3" => ["10.3.3", "rubocop-ruby2_3", "3.0.7"],
      "2.4" => ["12.3.3", "rubocop-ruby2_4", "3.0.7"],
      "2.5" => ["14.3.3", "rubocop-ruby2_5", "3.0.7"],
      "2.6" => ["16.3.3", "rubocop-ruby2_6", "3.0.7"],
      "2.7" => ["18.4.3", "rubocop-ruby2_7", "3.0.7"],
      "3.0" => ["20.4.3", "rubocop-ruby3_0", "3.0.7"],
      "3.1" => ["22.3.3", "rubocop-ruby3_1", "3.0.7"],
      "3.2" => ["24.2.3", "rubocop-ruby3_2", "3.0.8"]
    }

    expected_floors.each do |minimum_ruby, (rubocop_lts, rubocop_ruby, rubocop_ruby_floor)|
      expect(matrix.rubocop_template_tokens(Gem::Version.new(minimum_ruby))).to eq([
        "\"~> #{rubocop_lts.split(".").first(2).join(".")}\", \">= #{rubocop_lts}\"",
        rubocop_ruby,
        "\"~> #{rubocop_ruby_floor.split(".").first(2).join(".")}\", \">= #{rubocop_ruby_floor}\""
      ])
    end
  end
end
