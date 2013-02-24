#!/usr/bin/env ruby
require 'set'
require 'date'

class FuzzyDate
  def initialize(date)
    @date = date
  end

  def exact
    @date
  end

  def ===(other)
    y, m, d = other.split('-').map(&:to_i)
    Date.new(y, m, d) <= @date
  end
end

class Integer
  def days
    FuzzyDate.new(Date.today + self)
  end

  alias day days
end

class Item
  attr_accessor :id, :name, :tags

  def to_s
    if name
      "#{id} #{name}"
    else
      id
    end
  end

  def blocks
    tags["blocks"].to_s.split(" ")
  end

  def done?
    tags["done"]
  end

  def tags
    @tags ||= {}
  end

  def tag(name)
    tags[name]
  end
end

class ItemList
  attr_reader :list, :blocked

  def initialize
    @list = []
    @blocked = Hash.new { |h, k| h[k] = [] }
    @map = {}
  end

  def each(&blk)
    @list.each(&blk)
  end

  def <<(item)
    item.blocks.each do |id|
      @blocked[id] << item
    end

    @list << item
    @map[item.id] = item
  end

  def find(id)
    @map[id]
  end
end

class FilterContext
  def initialize(list, item, query)
    @list = list
    @item = item
    @query = query
  end

  def valid?
    instance_eval(@query)
  end

  def today
    Date.today
  end

  def tomorrow
    today + 1
  end

  def rest
    !$seen.include?(@item)
  end

  def blocked
    @list.blocked[@item.id].any? do |item|
      FilterContext.new(@list, item, @query).valid?
    end
  end

  def with_parents(item)
    return [] if item.nil?
    parents = item.blocks.flat_map { |i| with_parents(@list.find(i)) }
    [item, *parents].uniq
  end

  def method_missing(name, *args, &blk)
    name = name.to_s

    if name.chomp!("!")
      check = with_parents(@item)
    else
      check = [@item]
    end

    check.any? do |item|
      value = item.tag(name)
      matches?(value, args[0])
    end
  end

  def matches?(obj, expr)
    return unless obj

    case expr
    when String
      obj =~ /\b#{Regexp.escape(expr)}\b/
    when Date
      obj == expr.to_s
    when FuzzyDate
      expr === obj
    when nil
      true
    else
      raise "Unknown expression: #{expr.inspect}"
    end
  end
end

file = ARGV[0].chomp('v')
current = nil
items = ItemList.new

File.open(file, 'r') do |f|
  f.each_line do |line|
    case line
    when /^\* (\S+)/
      items << current if current
      current = Item.new
      current.id = $1
      current.name = $'.strip
    when /^  :(\S+)/
      current.tags[$1] = $'.strip
    end
  end
end

items << current if current

$seen = Set.new
cmd = queue = nil
state = :before
states = {
  before: proc do |line|
    next if line.empty?
    case line
    when />(.*)$/
      cmd = $1
      queue = []
      state = :gather
      puts line
    else
      puts line
    end
  end,

  gather: proc do |line|
    if line.strip.empty?
      res = []
      items.each do |item|
        if FilterContext.new(items, item, cmd).valid?
          $seen << item
          res << item
        end
      end
      queue.select! { |id, title| res.any? { |item| item.id == id } }
      res.reject! { |item| queue.any? { |id, title| item.id == id } }
      puts queue.map { |x| x.join(' ') }
      puts res

      state = :before
      puts unless line.empty?
      next
    end

    queue << line.strip.split(' ', 2)
  end
}

ARGF.each_line do |line|
  states[state].call(line)
end

states[state].call('')

