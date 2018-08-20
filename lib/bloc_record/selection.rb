require 'sqlite3'

module Selection
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    elsif BlocRecord::Utility.valid_ids?(ids)
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL
      rows_to_array(rows)
    else
      puts "Invalid Ids #{ids}"
    end
  end

  def find_one(id)
    if BlocRecord::Utility.valid_ids?(ids)
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      init_object_from_row(row)
    else
      puts "Invalid Ids #{ids}"
    end
  end

  def find_by(attribute,value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num}
      SQL

      rows_to_array(rows)
    elsif num == 1
      take_one
    else
      puts "invalid num #{num}"
    end
  end

  def take_one
    row = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def find_each(start: 0, batch_size: count, &block)
    connection.execute("SELECT #{columns.join ","} FROM #{table} LIMIT #{batch_size} OFFSET #{start}") do |result|
        yield result
    end if block_given?
  end

  def find_in_batches(start: 0, batch_size: count, &block)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{batch_size} OFFSET #{start}
    SQL
    yield rows, batch_size if block_given?
  end

  def method_missing(m, *args, &block)
    if m.match(/find_by/)
      element = m.to_s.split("_")
      attri = element[2..-1].join("_")
      if columns.include?(attri)
        find_by(attri, args[1].to_s)
      else
        puts "The attribute #{attri} does not exist."
        gets
      end
    else
      puts "The method #{m} is not a valid input."
      gets
    end
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)])}
  end
end
