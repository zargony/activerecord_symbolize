require 'rubygems'
require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'active_record'
require 'action_controller'
require 'action_view'
require 'symbolize'
require File.join(File.dirname(__FILE__), '..', 'init')

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
require File.dirname(__FILE__) + "/db/create_testing_structure"
I18n.load_path += Dir[File.join(File.dirname(__FILE__), "locales", "*.{rb,yml}")]
I18n.default_locale = "pt"
CreateTestingStructure.migrate(:up)


Spec::Runner.configure do |config|


end
