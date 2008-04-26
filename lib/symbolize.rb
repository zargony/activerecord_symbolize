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
  #     symbolize :gender
  #     validates_inclusion_of :gender, :in => [:female, :male]
  #   end
  module ClassMethods
    # Specifies that values of the given attributes should be returned
    # as symbols. The table column should be created of type string.
    def symbolize (*attr_names)
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
    write_attribute(attr_name, (value.to_sym.to_s rescue nil))
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
    # Since symbols always contain save characters (no backslash or apostrophe), it's
    # save to skip calling ActiveRecord::ConnectionAdapters::Quoting#quote_string here
    "'#{self.to_s}'"
  end
end
