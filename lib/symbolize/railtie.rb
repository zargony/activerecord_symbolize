# Rails 3 initialization
module Symbolize
  if defined? Rails::Railtie
    require 'rails'
    class Railtie < Rails::Railtie
      initializer 'symbolize.insert_into_active_record' do
        ActiveSupport.on_load :active_record do
          ActiveRecord::Base.extend(Symbolize::ClassMethods)
        end
      end
    end
  end
end

