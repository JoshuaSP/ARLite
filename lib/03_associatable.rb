require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name = options[:class_name] || "#{name.capitalize}"
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.foreign_key = options[:foreign_key] || "#{self_class_name.underscore}_id".to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name = options[:class_name] || "#{name.to_s.singularize.camelcase}"
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      return nil unless fkey = self.send(options.foreign_key) # assignment and check for nil in one line
      options.model_class.new(DBConnection.execute(<<-SQL).first)
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.primary_key} = #{fkey}
      SQL
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    assoc_options[name] = options
    define_method(name) do
      options.model_class.parse_all(DBConnection.execute(<<-SQL))
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.foreign_key} = #{self.send(options.primary_key)}
      SQL
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
