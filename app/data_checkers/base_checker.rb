class BaseChecker
  include Canopy::Configurable

  config :title,       as: :string
  config :description, as: :string
  config :columns,     as: :array
  config :rows,        as: :block
  config :row_id,      as: :block, default: :default_row_id

  def default_row_id(row)
    row[0]
  end

  def initialize(console: false)
    @console = console
  end

  def console?
    @console
  end

  def check!
    items = Array.wrap(rows).sort_by do |row|
      row ? row_id(row) : nil
    end
    [name, items.empty?, title, Array.wrap(columns), items, digest(items)]
  end

  def display!
    _, _, title, columns, rows, = check!
    puts(Terminal::Table.new(title: title, headings: columns, rows: rows))
    puts("Total rows: #{rows.length}")
  end

  def name
    self.class.to_s.underscore
  end

  def digest(rows)
    Digest::MD5.hexdigest("#{name}-#{rows.flatten.join('-').gsub(/\s/, '-')}")
  end
end
