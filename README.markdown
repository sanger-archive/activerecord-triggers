# ActiveRecord triggers
This gem enables ActiveRecord to understand triggers, at least in MySQL.

Install with:

    gem "activerecord-triggers", "~> 0.0.1"

Usage:

    class DefineTrigger < ActiveRecord::Migration
      def up
        after_trigger('some trigger code', :name => 'my_trigger', :event => 'insert', :on => 'one_table')
      end

      def down
        drop_trigger('my_trigger')
      end
    end

This creates a trigger that will fire after an insert has been made on `one_table`.  There is also a `before_trigger` method.

Note that `rake db:schema:dump` will output the triggers you have created.

Feel free to fork and submit pull requests.
