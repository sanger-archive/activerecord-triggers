require 'active_support/concern'

module ActiveRecord::Triggers
  module SchemaDumper
    extend ActiveSupport::Concern

    included do
      alias_method_chain(:trailer, :triggers)
    end

    # Override the standard behaviour of the tables method so that the triggers can be
    # dumped after all of the normal processing has completed.
    def trailer_with_triggers(stream)
      dump_triggers(stream)
      trailer_without_triggers(stream)
      stream
    end

    # Dumps the triggers that are defined
    def dump_triggers(stream)
      triggers_dumped = false
      @connection.triggers do |trigger_type, code, details|
        stream.puts(%Q{  #{trigger_type}(#{code.inspect}, #{details.inspect})})
        triggers_dumped = true
      end
      stream.puts if triggers_dumped
    end
    private :dump_triggers
  end
end

# Uurggh. Have to include all of these for ActiveRecord::SchemaDumper
require 'active_record'
require 'active_record/base'
require 'active_record/schema_dumper'

class ActiveRecord::SchemaDumper
  include ActiveRecord::Triggers::SchemaDumper
end
