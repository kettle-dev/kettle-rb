# frozen_string_literal: true

namespace :kettle do
  namespace :rb do
    namespace :platform_support do
      desc "Regenerate lib/kettle/rb/platform_support/data.rb from the GitHub releases API and ruby/setup-ruby"
      task :generate do
        require File.expand_path(File.join(File.dirname(__FILE__), "..", "lib", "kettle", "rb", "platform_support", "generator"))

        path = Kettle::Rb::PlatformSupport::Generator.new.write
        puts "Wrote #{path}"
      end
    end
  end
end
