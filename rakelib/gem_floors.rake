# frozen_string_literal: true

namespace :kettle do
  namespace :rb do
    namespace :gem_floors do
      desc "Regenerate lib/kettle/rb/gem_floors/data.rb from rubygems.org and ruby-advisory-db (UPDATE_ADVISORY_DB=false skips the database update)"
      task :generate do
        require File.expand_path(File.join(File.dirname(__FILE__), "..", "lib", "kettle", "rb", "gem_floors", "generator"))

        unless ENV.fetch("UPDATE_ADVISORY_DB", "true").casecmp("false").zero?
          require "bundler/audit/database"
          Bundler::Audit::Database.update!(:quiet => true)
        end

        path = Kettle::Rb::GemFloors::Generator.new.write
        puts "Wrote #{path}"
      end
    end
  end
end
