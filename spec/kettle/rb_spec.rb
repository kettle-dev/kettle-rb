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
      "\"~> 12.3\", \">= 12.3.1\"",
      "rubocop-ruby2_4",
      "\"~> 3.0\", \">= 3.0.5\""
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
      "\"~> 0.3\", \">= 0.3.1\"",
      "rubocop-ruby1_8",
      "\"~> 2.0\", \">= 2.0.5\""
    ]

    expect(matrix.rubocop_template_tokens(nil)).to eq(oldest_tokens)
    expect(matrix.rubocop_template_tokens("")).to eq(oldest_tokens)
    expect(matrix.rubocop_template_tokens("not-a-version")).to eq(oldest_tokens)
  end

  it "accepts Gem::Version minimum Ruby inputs" do
    matrix = Kettle::Rb::CompatMatrix

    expect(matrix.rubocop_template_tokens(Gem::Version.new("3.2"))).to eq([
      "\"~> 24.2\", \">= 24.2.1\"",
      "rubocop-ruby3_2",
      "\"~> 3.0\", \">= 3.0.6\""
    ])
  end
end
