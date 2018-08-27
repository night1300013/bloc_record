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
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL
    init_object_from_row(row)
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

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end
    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    arr = []
    args.each do |arg|
      case arg
      when String
        arr << arg
      when Symbol
        arr << arg.to_s
      when Hash
        arr << arg.map{|key, value| "#{key} #{value}"}
      end
    end
    order = arr.join(",")

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id" }.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
          SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{arg.first} ON #{arg.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        joins = arg.first.map{|key, value| "INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id"}#.join(" ")
        puts joins
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{joins}
        SQL
      end
    end

    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end
