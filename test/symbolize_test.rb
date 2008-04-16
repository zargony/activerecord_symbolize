PLUGIN_ROOT = File.dirname(__FILE__) + '/..'
RAILS_ROOT = PLUGIN_ROOT + '/../../..'

require RAILS_ROOT + '/vendor/rails/activerecord/lib/active_record'
require PLUGIN_ROOT + '/lib/symbolize'
require PLUGIN_ROOT + '/init'

require 'test/unit'

# Establish a temporary sqlite3 db for testing
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Base.connection.execute("
  CREATE TABLE 'users' (
    'id' INTEGER PRIMARY KEY NOT NULL,
    'name' VARCHAR(255) NOT NULL,
    'status' VARCHAR(255) NOT NULL
  );")

# Make with_scope public-usable for testing
class << ActiveRecord::Base
  public :with_scope
end

# Test model
class User < ActiveRecord::Base
  symbolize :status
end

# Test records
User.create(:name => 'Anna', :status => :active)
User.create(:name => 'Bob', :status => :inactive)

class SymbolizeTest < Test::Unit::TestCase
  def setup
    @user = User.find(:first)
  end

  def test_plugin_loaded
    assert ActiveRecord::Base.respond_to?(:symbolize)
  end

  # Test attribute setter and getter

  def test_symbolize_nil
    @user.status = nil
    assert_nil @user.status
    assert_nil @user.status_before_type_cast
    assert_nil @user.read_attribute(:status)
  end

  def test_symbolize_blank
    @user.status = ''
    assert_nil @user.status
    assert_nil @user.status_before_type_cast
    assert_nil @user.read_attribute(:status)
  end

  def test_symbolize_symbol
    @user.status = :testing
    assert_equal :testing, @user.status
    assert_equal 'testing', @user.status_before_type_cast
    assert_equal 'testing', @user.read_attribute(:status)
  end

  def test_symbolize_string
    @user.status = 'testing'
    assert_equal :testing, @user.status
    assert_equal 'testing', @user.status_before_type_cast
    assert_equal 'testing', @user.read_attribute(:status)
  end

  def test_symbolize_number
    @user.status = 123
    assert_nil @user.status
    assert_nil @user.status_before_type_cast
    assert_nil @user.read_attribute(:status)
  end

  # Test quoted_id of symbols

  def test_symbols_quoted_id
    @user.status = :active
    assert_equal "'active'", @user.status.quoted_id
  end

  # Test finders

  def test_symbolized_finder
    assert_equal ['Bob'], User.find(:all, :conditions => { :status => :inactive }).map(&:name)
    assert_equal ['Bob'], User.find_all_by_status(:inactive).map(&:name)
  end

  # Test with_scope

  def test_symbolized_with_scope
    User.with_scope(:find => { :conditions => { :status => :inactive }}) do
      assert_equal ['Bob'], User.find(:all).map(&:name)
    end
  end

  # TODO: Test if existing ActiveRecord tests won't break by running them with Symbolize loaded
end
