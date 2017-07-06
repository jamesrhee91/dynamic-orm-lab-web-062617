require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  ATTRIBUTES = {
    id: "INTEGER PRIMARY KEY",
    name: "TEXT",
    grade: "INTEGER"
  }

  attr_accessor(*ATTRIBUTES.keys)

  def initialize(att={})
    att.each do |k, v|
      self.send("#{k}=", v)
    end
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{table_name}')"
    result = []
    DB[:conn].execute(sql).each {|col| result << col["name"]}
    result.compact
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"

    DB[:conn].execute(sql, name)
  end

  def self.find_by(hash)
    insert = hash.keys.map(&:to_s).join
    value = hash.values
    sql = "SELECT * FROM #{self.table_name} WHERE #{insert} = ?"

    DB[:conn].execute(sql, value)
  end


  def save
    inserts = self.class.column_names.join(", ")
    questions_marks = ("?"*self.class.column_names.size).chars.join(", ")
    values = self.class.column_names.map {|att| self.send(att)}
    sql = "INSERT INTO #{self.class.table_name} (#{inserts}) VALUES (#{questions_marks})"

    DB[:conn].execute(sql, *values)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.class.table_name}")[0][0]
  end

  def table_name_for_insert
    "#{self.class.table_name}"
  end

  def col_names_for_insert
    self.class.column_names.reject {|e| e == "id"}.join(", ")
  end

  def values_for_insert
    att = self.col_names_for_insert.split(", ")
    att.map {|e| "'#{self.send(e)}'"}.join(", ")
  end


end
