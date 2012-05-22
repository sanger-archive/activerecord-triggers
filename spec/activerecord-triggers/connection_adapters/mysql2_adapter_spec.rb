require 'spec_helper'
require 'activerecord-triggers/connection_adapters/mysql2_adapter'

describe ActiveRecord::Triggers::ConnectionAdapters::Mysql2Adapter do
  subject do
    double(:connection).tap do |connection|
      class << connection
        def quote_table_name(name) ; "`#{name}`" ; end
        include ActiveRecord::Triggers::ConnectionAdapters::Mysql2Adapter
      end
    end
  end

  [ 'insert', 'update', 'delete' ].each do |point|
    context '#after_trigger' do
      it "installs the trigger after #{point}" do
        subject.should_receive(:execute).with("CREATE TRIGGER `trigger_name` AFTER #{point.upcase} ON `table` FOR EACH ROW trigger code")
        subject.after_trigger('trigger code', :name => 'trigger_name', :event => point, :on => 'table')
      end
    end

    context '#before_trigger' do
      it "installs the trigger before #{point}" do
        subject.should_receive(:execute).with("CREATE TRIGGER `trigger_name` BEFORE #{point.upcase} ON `table` FOR EACH ROW trigger code")
        subject.before_trigger('trigger code', :name => 'trigger_name', :event => point, :on => 'table')
      end
    end
  end

  context '#drop_trigger' do
    it "removes the trigger" do
      subject.should_receive(:execute).with("DROP TRIGGER IF EXISTS `trigger_name`")
      subject.drop_trigger('trigger_name')
    end

    it "removes multiple triggers" do
      subject.should_receive(:execute).with("DROP TRIGGER IF EXISTS `trigger1`")
      subject.should_receive(:execute).with("DROP TRIGGER IF EXISTS `trigger2`")
      subject.drop_trigger('trigger1', 'trigger2')
    end
  end

  context '#triggers' do
    let(:callback) { double(:callback) }

    after(:each) do
      subject.triggers(&callback.method(:call))
    end

    it 'does not yield if there are no triggers' do
      subject.should_receive(:select_all).with('SHOW TRIGGERS').and_return([])
      callback.should_receive(:call).never
    end

    [ 'before', 'after' ].each do |kind|
      [ 'insert', 'update', 'delete' ].each do |point|
        it "yields the details of the #{kind} #{point} trigger" do
          subject.should_receive(:select_all).with('SHOW TRIGGERS').and_return([
            { 'Trigger' => 'trigger', 'Event' => point.upcase, 'Timing' => kind.upcase, 'Table' => 'table', 'Statement' => 'trigger code' }
          ])
          callback.should_receive(:call).with(:"#{kind}_trigger", 'trigger code', :name => 'trigger', :event => point.to_sym, :on => 'table')
        end

        it 'yields multiple triggers' do
          subject.should_receive(:select_all).with('SHOW TRIGGERS').and_return([
            { 'Trigger' => 'trigger1', 'Event' => point.upcase, 'Timing' => kind.upcase, 'Table' => 'table1', 'Statement' => 'trigger code 1' },
            { 'Trigger' => 'trigger2', 'Event' => point.upcase, 'Timing' => kind.upcase, 'Table' => 'table2', 'Statement' => 'trigger code 2' }
          ])
          callback.should_receive(:call).with(:"#{kind}_trigger", 'trigger code 1', :name => 'trigger1', :event => point.to_sym, :on => 'table1')
          callback.should_receive(:call).with(:"#{kind}_trigger", 'trigger code 2', :name => 'trigger2', :event => point.to_sym, :on => 'table2')
        end
      end
    end
  end
end
