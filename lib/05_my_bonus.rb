require_relative '04_associatable2'

class Relation
  extend Searchable

  attr_accessor :sqlobj, :obj, :params

  def initialize(obj, params)
    if obj is_a? SQLObject
      @sqlobj = sqlobj
      @params = params
    elsif obj is_a? Relation
      @sqlobj = obj.sqlobj
      @params = obj.params.merge(params)
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

module Searchable
  def where(params)
    Relation.new(self, params)
  end
end
