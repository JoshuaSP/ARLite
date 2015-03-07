require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    params_string = params.map do |key, value|
      "#{key} = ?"
    end.join(" AND ")
    DBConnection.execute(<<-SQL, params.values).map { |res| self.new(res) }
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{params_string}
    SQL
  end
end

class SQLObject
  extend Searchable
end
