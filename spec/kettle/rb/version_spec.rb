# frozen_string_literal: true

require "anonymous_loader"
RSpec.describe Kettle::Rb::Version do
  it "executes the version file for coverage without redefining constants" do
    path = File.expand_path("../../../lib/kettle/rb/version.rb", __dir__)
    anonymous_namespace = AnonymousLoader.load(:files => path)

    expect(anonymous_namespace::Kettle::Rb::Version::VERSION).to eq(described_class::VERSION)
  end
end
