require 'spec_helper'

describe ActiveRecord::Triggers::SchemaDumper do
  let(:connection) do
    double(:connection)
  end

  subject do
    double(:dumper).tap do |dumper|
      # ActiveRecord::SchemaDumper uses an instance variable and provides no accessor for this:
      dumper.instance_variable_set(:@connection, connection)

      # Imbue the mock object with the ActiveRecord::SchemaDumper behaviour!
      class << dumper
        def trailer(stream) ; stream ; end
        include ActiveRecord::Triggers::SchemaDumper
      end
    end
  end

  context '#table' do
    let(:stream) do
      double(:stream)
    end

    before(:each) do
      subject.should_receive(:trailer_without_triggers).and_return('used stream')
    end

    after(:each) do
      subject.trailer(stream)
    end

    it 'does not dump non-existant triggers' do
      connection.should_receive(:triggers)
      stream.should_receive(:puts).never
    end

    it 'dumps a single trigger' do
      connection.should_receive(:triggers)
        .and_yield(:after_trigger, 'trigger code', :name => 'trigger name', :event => 'insert', :on => 'table')

      stream.should_receive(:puts).with(%Q{  after_trigger("trigger code", {:name=>"trigger name", :event=>"insert", :on=>"table"})})
      stream.should_receive(:puts)
    end

    it 'dumps multiple triggers' do
      connection.should_receive(:triggers)
        .and_yield(:before_trigger, 'trigger code 1', :name => 'trigger 1', :event => 'insert', :on => 'table1')
        .and_yield(:after_trigger,  'trigger code 2', :name => 'trigger 2', :event => 'insert', :on => 'table2')

      stream.should_receive(:puts).with(%Q{  before_trigger("trigger code 1", {:name=>"trigger 1", :event=>"insert", :on=>"table1"})})
      stream.should_receive(:puts).with(%Q{  after_trigger("trigger code 2", {:name=>"trigger 2", :event=>"insert", :on=>"table2"})})
      stream.should_receive(:puts)
    end
  end
end
