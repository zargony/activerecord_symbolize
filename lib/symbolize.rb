module Symbolize
  def self.included (base)
    base.extend(ClassMethods)
  end

  # Symbolize ActiveRecord attributes. Add
  #   symbolize :attr_name
  # to your model class, to make an attribute return symbols instead of
  # string values. Setting such an attribute will accept symbols as well
  # as strings. In the database, the symbolized attribute should have
  # the column-type :string.
  #
  # Example:
  #   class User < ActiveRecord::Base
  #     symbolize :gender, :in => [:female, :male]
  #   end
  module ClassMethods
    # Specifies that values of the given attributes should be returned
    # as symbols. The table column should be created of type string.
    def symbolize (*attr_names)
      configuration = {}
      configuration.update(attr_names.extract_options!)
      
      enum = configuration[:in] || configuration[:within]
      
      unless enum.nil?
        if enum.class == Hash
          values = enum
          enum   = enum.map { |key,value| key } 
        else
          values = Hash[*enum.collect { |v| [v, v.to_s.capitalize] }.flatten]
        end

        attr_names.each do |attr_name|
          attr_name = attr_name.to_s
          class_eval("#{attr_name.upcase}_VALUES = values")
          class_eval("def self.get_#{attr_name}_values; #{attr_name.upcase}_VALUES; end")
        end
        
        class_eval("validates_inclusion_of :#{attr_names.join(', :')}, configuration")
      end

      attr_names.each do |attr_name|
        attr_name = attr_name.to_s
        class_eval("def #{attr_name}; read_and_symbolize_attribute('#{attr_name}'); end")
        class_eval("def #{attr_name}= (value); write_symbolized_attribute('#{attr_name}', value); end")
      end
    end
  end

  # Return an attribute's value as a symbol or nil
  def read_and_symbolize_attribute (attr_name)
    read_attribute(attr_name).to_sym rescue nil
  end

  # Write a symbolized value
  def write_symbolized_attribute (attr_name, value)
    write_attribute(attr_name, (value.to_sym && value.to_sym.to_s rescue nil))
  end
end

# The Symbol class is extended by method quoted_id which returns a string.
# The idea behind this is, that symbols are converted to plain strings
# when being quoted by ActiveRecord::ConnectionAdapters::Quoting#quote.
# This makes it possible to work with symbolized attibutes in sql conditions.
# E.g. validates_uniqueness_of could not use :scope with a symbolized
# attribute, because AR quotes it to YAML:
#  "... AND status = '--- :active\n'"
# Having support for quoted_id in Symbol, makes AR quoting symbols correctly:
#  "... AND status = 'active'"
# NOTE: Normally quoted_id should be implemented as a singleton method
#       only used on symbols returned by read_and_symbolize_attribute,
#       but unfortunately this is not possible since Symbol is an immediate
#       value and therefore does not support singleton methods.
class Symbol
  def quoted_id
    # A symbol can contain almost every character (even a backslash or an
    # apostrophe), so make sure to properly quote the string value here.
    "'#{ActiveRecord::Base.connection.quote_string(self.to_s)}'"
  end
end
