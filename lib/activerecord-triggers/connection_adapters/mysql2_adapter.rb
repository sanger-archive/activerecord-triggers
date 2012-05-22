require 'active_record/connection_adapters/mysql2_adapter'

module ActiveRecord::Triggers
  module ConnectionAdapters
    module Mysql2Adapter
      # Defines a trigger that will fire after the specified event
      def after_trigger(code, details)
        create_trigger(:after, code, details)
      end

      # Defines a trigger that will fire before the specified event
      def before_trigger(code, details)
        create_trigger(:before, code, details)
      end

      def create_trigger(at, code, details)
        execute("CREATE TRIGGER #{quote_table_name(details[:name])} #{at.to_s.upcase} #{details[:event].to_s.upcase} ON #{quote_table_name(details[:on])} FOR EACH ROW #{code}")
      end
      private :create_trigger

      # Drops the specified trigger(s)
      def drop_trigger(*names)
        names.each { |name| execute("DROP TRIGGER IF EXISTS #{quote_table_name(name)}") }
      end

      # Yields each of the triggers that are defined in the current database
      def triggers(&block)
        select_all("SHOW TRIGGERS").each do |details|
          yield(
            :"#{details['Timing'].downcase}_trigger",
            details['Statement'],
            :name  => details['Trigger'],
            :event => details['Event'].downcase.to_sym,
            :on    => details['Table']
          )
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  class ActiveRecord::ConnectionAdapters::Mysql2Adapter
    include ActiveRecord::Triggers::ConnectionAdapters::Mysql2Adapter
  end
end
