require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject  
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL).first.map { |col| col.to_sym }
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
  end

  def self.finalize!
    self.columns.each do |column|
      define_method (column) do
        attributes[column]
      end
      define_method ("#{column}=") do |val|
        attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    self.parse_all(DBConnection.execute(<<-SQL))
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
  end

  def self.parse_all(hashes)
    hashes.map do |hash|
      self.new(hash)
    end
  end

  def self.find(id)
    obj = DBConnection.execute(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL
    obj ? self.new(obj) : nil
  end

  def initialize(params = {})
    params.each do |key, value|
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym)
      self.send("#{key}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # debugger
    @attributes.values
  end

  def insert
    range = attributes.keys.first == :id ? (1..-1) : (0..-1)
    column_string = attributes.keys[range].join(", ")
    qstring = "(#{(["?"] * attribute_values[range].length).join(", ")})"
    DBConnection.execute(<<-SQL, attribute_values[range])
      INSERT INTO
        #{self.class.table_name} (#{column_string})
      VALUES
        #{qstring}
    SQL
    self.id = DBConnection.execute(<<-SQL)[0]['maxid']
      SELECT
        MAX(id) AS maxid
      FROM
        #{self.class.table_name}
    SQL
  end

  def update
    range = (1..-1)
    setstring = attributes.keys[range].map do |key|
      "#{key} = ?"
    end.join(", ")
    DBConnection.execute(<<-SQL, attribute_values[range] + [id])
      UPDATE
        #{self.class.table_name}
      SET
        #{setstring}
      WHERE
        id = ?
    SQL
  end

  def save
    if id
      in_db = DBConnection.execute(<<-SQL)[0]['c'] == 1
        SELECT
          COUNT(*) AS c
        FROM
          #{self.class.table_name}
        WHERE
          id = #{id}
      SQL
      if in_db
        update
      else
        insert
      end
    else
      insert
    end
  end

  def ==(obj)
    @attributes.all? do |attrib, val|
      val = obj.send(attrib)
    end
  end
end
