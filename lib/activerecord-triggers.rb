require "activerecord-triggers/version"

module ActiveRecord
  module Triggers
    require "activerecord-triggers/schema_dumper"
    require "activerecord-triggers/connection_adapters/mysql2_adapter"
  end
end
