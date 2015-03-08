require_relative '04_associatable2'
require 'byebug'

module Searchable
  def where(params)
    Relation.new(self, params)
  end
end

class Relation
  include Searchable

  attr_accessor :sqlobj, :obj, :params

  def initialize(obj, params)
    if obj.class.to_s == "Relation"
      @sqlobj = obj.sqlobj
      @params = obj.params.merge(params)
    elsif obj.class.to_s == "Class" && obj.superclass == SQLObject
      @sqlobj = obj
      @params = params
    else
      raise "cannot compute relation"
    end
  end

  def all
    # eventually to be replaced with fancy Enumerable mixin stuff
    params_string = params.map do |key, value|
      "#{key} = ?"
    end.join(" AND ")
    DBConnection.execute(<<-SQL, params.values).map { |res| sqlobj.new(res) }
      SELECT
        *
      FROM
        #{sqlobj.table_name}
      WHERE
        #{params_string}
    SQL
  end
end

module Associatable
  def has_many_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      through_table = through_options.table_name
      source_table = source_options.table_name
      debugger
      source_options.model_class.parse_all(DBConnection.execute(<<-SQL))
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table} ON #{through_table}.#{source_options.primary_key} = #{source_table}.#{source_options.foreign_key}
        WHERE
          #{through_table}.#{through_options.foreign_key} = #{self.send(through_options.primary_key)}
      SQL
    end
  end
end

module Validatable
  def save
    raise_errors unless valid?
    super
  end

  def raise_errors
    raise @errors.join("\n")
  end

  def validates(field, params)
    define_method(:valid?) do
      params.each do |param, value|
        feild_value = self.send(field)
        case param
        when :presence
          @errors << "#{field} cannot be empty." if field_value.nil?
        when :uniqueness
          unique = self.class.where(field => field_value).empty?
          # TODO : have to handle case when updating a record, take out self
          @errors << "#{field} must be unique." unless unique
        when :length
          case value.keys.first
          when :minimum
            failure = field_value > value.values.first
            @errors << "#{field} must be less than #{value.values.first} chars." if failure
          when :in
            failure = !value.values.first.cover?(field_value)
            @errors << "#{field} must be less than #{value.values.first} chars." if failure
          when :
            failure = field_value > value.values.first
            @errors << "#{field} must be less than #{value.values.first} chars." if failure
          when :minimum
            failure = field_value > value.values.first
            @errors << "#{field} must be less than #{value.values.first} chars." if failure


  end
end

class SQLObject
  extend Validatable
end
