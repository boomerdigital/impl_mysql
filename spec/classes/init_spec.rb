require 'spec_helper'
describe 'impl_mysql' do

  context 'with defaults for all parameters' do
    it { should contain_class('impl_mysql') }
  end
end
