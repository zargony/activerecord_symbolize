PLUGIN_ROOT = File.dirname(__FILE__) + '/..'
RAILS_ROOT = PLUGIN_ROOT + '/../../rails'

require RAILS_ROOT  + '/activerecord/lib/active_record'
require RAILS_ROOT  + '/actionpack/lib/action_controller'
require RAILS_ROOT  + '/actionpack/lib/action_view'
require PLUGIN_ROOT + '/lib/symbolize'
require PLUGIN_ROOT + '/init'

require 'test/unit'

# Establish a temporary sqlite3 db for testing
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Base.connection.execute("
  CREATE TABLE 'users' (
    'id' INTEGER PRIMARY KEY NOT NULL,
    'name' VARCHAR(255) NOT NULL,
    'other' VARCHAR(255) NOT NULL,
    'status' VARCHAR(255) NOT NULL,
    'so' VARCHAR(255) NOT NULL
  );")

# Make with_scope public-usable for testing
class << ActiveRecord::Base
  public :with_scope
end

# Test model
class User < ActiveRecord::Base
  symbolize :other
  symbolize :status , :in => [:active, :inactive]
  symbolize :so, :allow_blank => true, :in => {
    :mac   => 'Mac OS X',
    :win   => 'Windows',
    :linux => 'Linux'
  }
  symbolize :office, :allow_blank => true, :in => [
    [:kde , 'Koffice'],
    [:ms  , 'Microsoft Office'],
    [:open, 'Open Office']
  ]
end

# Test records
User.create(:name => 'Anna', :other => :fo, :status => :active  , :so => :linux, :office => :ms)
User.create(:name => 'Bob' , :other => :bar,:status => :inactive, :so => :mac, :office => :kde)

class SymbolizeTest < Test::Unit::TestCase
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def setup
    @options_status = [['Active', :active], ['Inactive', :inactive]]
    @options_office = [["Koffice", :kde]  , ["Microsoft Office", :ms], ["Open Office", :open]]
    @options_so     = [["Linux", :linux]  , ["Mac OS X", :mac], ["Windows", :win]]
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
  
  def test_other_validates 
    @user.other = nil
    assert @user.valid?
    @user.other = ''
    assert @user.valid?
  end
  
  def test_status_validates
    @user.status = nil
    assert !@user.valid?
    assert @user.errors.on(:status)
    @user.status = ''
    assert !@user.valid?
    assert @user.errors.on(:status)
    @user.status = :not_valid
    assert !@user.valid?
    assert @user.errors.on(:status)
    @user.status = :active
    assert @user.valid?
  end
  
  def test_so_validates
    @user.so = nil
    assert @user.valid?
    @user.so = ''
    assert @user.valid?    
  end
  
  def test_get_values 
    assert_equal({ :active => 'Active', :inactive => 'Inactive' }, User.get_status_values)
    assert_equal({ :win => "Windows", :mac => "Mac OS X", :linux => "Linux"}, User.get_so_values)
  end
    
  def test_symbolize_symbol
    @user.status = :active
    assert_equal :active,  @user.status
    assert_equal 'active', @user.status_before_type_cast
    assert_equal 'active', @user.read_attribute(:status)
  end

  def test_symbolize_string
    @user.status = 'inactive'
    assert_equal :inactive,  @user.status
    assert_equal 'inactive', @user.status_before_type_cast
    assert_equal 'inactive', @user.read_attribute(:status)
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

  def test_symbols_with_weird_chars_quoted_id
    @user.status = :"weird'; chars"
    assert_equal "weird'; chars", @user.status_before_type_cast
    assert_equal "weird'; chars", @user.read_attribute(:status)
    assert_equal "'weird''; chars'", @user.status.quoted_id
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

  # Test humazine
  def test_symbolize_humanize
    assert_equal 'Active', @user.status_humanize
    
    assert_equal 'Linux' , @user.so_humanize
    @user.so = :mac
    assert_equal "Mac OS X", @user.so_humanize

    assert_equal 'Fo'    , @user.other_humanize
    @user.other = :foooo
    assert_equal 'Foooo', @user.other_humanize
  end

  def test_helper_select_sym
    output = "<select id=\"user_status\" name=\"user[status]\">#{options_for_select(@options_status, @user.status)}</select>"
    assert_equal(output, select_sym("user", "status", nil))
    
    @user.status = :inactive
    output = "<select id=\"user_status\" name=\"user[status]\">#{options_for_select(@options_status, @user.status)}</select>"
    assert_equal(output, select_sym("user", "status", nil))
  end
  
  def test_helper_select_sym_order
    output_so     = "<select id=\"user_so\" name=\"user[so]\">#{options_for_select(@options_so, @user.so)}</select>"
    output_office = "<select id=\"user_office\" name=\"user[office]\">#{options_for_select(@options_office, @user.office)}</select>"

    assert_equal output_so, select_sym("user", "so", nil)
    assert_equal output_office, select_sym("user", "office", nil)
  end

  def test_helper_radio_sym
    output = radio_sym("user", "status", nil)
    assert_equal("<label>Active: <input checked=\"checked\" id=\"user_status_active\" name=\"user[status]\" type=\"radio\" value=\"active\" /></label><label>Inactive: <input id=\"user_status_inactive\" name=\"user[status]\" type=\"radio\" value=\"inactive\" /></label>", output)
  end

  # TODO: Test if existing ActiveRecord tests won't break by running them with Symbolize loaded
end

