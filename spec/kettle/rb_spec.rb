# frozen_string_literal: true

RSpec.describe Kettle::Rb do
  it "has a version number" do
    expect(Kettle::Rb::VERSION).not_to be_nil
  end

  it "exposes the Ruby compatibility matrix" do
    matrix = Kettle::Rb::CompatMatrix

    expect(matrix.entry("jruby-10.1").ruby).to eq("jruby-10.1.0.0")
    expect(matrix.entry("truffleruby-34.0").ruby).to eq("truffleruby-34.0.1")
    expect(matrix.workflow_ruby_floor("truffleruby-23.1")).to eq("3.1")
    expect(matrix.engine_workflow("truffle")).to eq("truffleruby")
  end

  it "selects RuboCop LTS data from the matrix" do
    matrix = Kettle::Rb::CompatMatrix

    expect(matrix.rubocop_template_tokens(Gem::Version.new("2.4"))).to eq([
      "\"~> 12.3\", \">= 12.3.0\"",
      "rubocop-ruby2_4",
      "\"~> 3.0\", \">= 3.0.2\""
    ])
    expect(matrix.rubocop_lts_branch_for_gem("rubocop-ruby3_2")).to eq("r3_2-even-v24")
    expect(matrix.rubocop_ruby_gem?("rubocop-ruby3_2")).to be(true)
    expect(matrix.rubocop_ruby_gem?("rubocop-lts")).to be(false)
  end
end
