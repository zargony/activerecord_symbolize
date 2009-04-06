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
  #     symbolize :so, :in => {
  #       :linux   => "Linux",
  #       :mac     => "Mac OS X"
  #     }
  #     symbolize :gui, , :in => [:gnome, :kde, :xfce], :allow_blank => true
  #     symbolize :browser, :in => [:firefox, :opera], :i18n => false
  #   end
  #
  # It will automattically lookup for i18n:
  #
  # activerecord:
  #   attributes:
  #     user:
  #       enums:
  #         gender:
  #           female: Girl
  #           male: Boy
  #
  # You can skip i18n lookup with :i18n => false
  #   symbolize :gender, :in => [:female, :male], :i18n => false
  #
  # Its possible to use boolean fields also.
  #   symbolize :switch, :in => [true, false]
  #
  #   ...
  #     switch:
  #       "true": On
  #       "false": Off
  #       "nil": Unknown
  #
  module ClassMethods
    # Specifies that values of the given attributes should be returned
    # as symbols. The table column should be created of type string.
    def symbolize (*attr_names)
      configuration = {}
      configuration.update(attr_names.extract_options!)

      enum = configuration[:in] || configuration[:within]
      i18n = configuration[:i18n].nil? ? true : configuration[:i18n]

      unless enum.nil?
        attr_names.each do |attr_name|
          attr_name = attr_name.to_s
          if i18n && enum.class != Hash
            values = Hash[*enum.map { |v| [v, I18n.translate("activerecord.attributes.#{self.to_s.downcase}.enums.#{attr_name}.#{v}")] }.flatten]
          elsif enum.class == Hash
            values = enum
            enum   = enum.map { |key,value| [value, key] }
            enum.sort! { |a, b| a[0] <=> b[0] }
          else
            values = Hash[*enum.collect { |v| [v, v.to_s.capitalize] }.flatten]
          end
          class_eval("#{attr_name.upcase}_VALUES = values")
          class_eval("def self.get_#{attr_name}_values; #{attr_name.upcase}_VALUES.map(&:reverse); end")
        end

        class_eval("validates_inclusion_of :#{attr_names.join(', :')}, configuration")
      end

      attr_names.each do |attr_name|
        attr_name = attr_name.to_s
        class_eval("def #{attr_name}; read_and_symbolize_attribute('#{attr_name}'); end")
        class_eval("def #{attr_name}_text; read_i18n_attribute('#{attr_name}'); end") if i18n
        class_eval("def #{attr_name}= (value); write_symbolized_attribute('#{attr_name}', value); end")
      end
    end
  end

  # String becomes symbol, booleans string and nil nil.
  def symbolize_attribute attr
    case attr
      when String then attr.to_sym
      when Symbol, TrueClass, FalseClass then attr
      else nil
    end
  end

  # Return an attribute's value as a symbol or nil
  def read_and_symbolize_attribute attr_name
    symbolize_attribute read_attribute(attr_name)
  end

  # Return an attribute's i18n
  def read_i18n_attribute attr_name
    I18n.translate("activerecord.attributes.#{self.class.to_s.downcase}.enums.#{attr_name}.#{read_attribute(attr_name)}") #.to_sym rescue nila
  end

  # Write a symbolized value
  # Watch out for booleans.
  def write_symbolized_attribute attr_name, value
    val = { "true" => true, "false" => false }[value]
    val = symbolize_attribute(value) if val.nil?
    write_attribute(attr_name, val)
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
