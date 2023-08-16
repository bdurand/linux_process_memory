# frozen_string_literal: true

# This class will read the smap files for a process on a Linux system and report
# the memory usage for that process.
class LinuxProcessMemory
  class NotSupportedError < StandardError
    def initialize
      super("LinuxProcessMemory is only supported on Linux systems")
    end
  end

  LINUX_MATCHER = /linux/i
  private_constant :LINUX_MATCHER

  UNIT_CONVERSION = {
    "bytes" => 1,
    "kilobytes" => 1024,
    "megabytes" => 1024 * 1024,
    "gigabytes" => 1024 * 1024 * 1024,
    "kb" => 1024,
    "mb" => 1024 * 1024,
    "gb" => 1024 * 1024 * 1024,
    "k" => 1024,
    "m" => 1024 * 1024,
    "g" => 1024 * 1024 * 1024
  }.freeze
  private_constant :UNIT_CONVERSION

  attr_reader :pid

  class << self
    def linux?
      RUBY_PLATFORM.match?(LINUX_MATCHER)
    end
  end

  def initialize(pid = Process.pid)
    raise NotSupportedError unless self.class.linux?

    @pid = pid
    @stats = read_smaps
  end

  def total(units = :bytes)
    convert_units(@stats[:Rss] + @stats[:Swap], units)
  end

  def rss(units = :bytes)
    convert_units(@stats[:Rss], units)
  end

  alias_method :resident, :rss

  def pss(units = :bytes)
    convert_units(@stats[:Pss], units)
  end

  alias_method :proportional, :pss

  def uss(units = :bytes)
    convert_units(@stats[:Private_Clean] + @stats[:Private_Dirty], units)
  end

  alias_method :unique, :uss

  def swap(units = :bytes)
    convert_units(@stats[:Swap], units)
  end

  def shared(units = :bytes)
    convert_units(@stats[:Shared_Clean] + @stats[:Shared_Dirty], units)
  end

  def referenced(units = :bytes)
    convert_units(@stats[:Referenced], units)
  end

  private

  def read_smaps
    stats = Hash.new(0)
    return stats unless File.exist?(smap_rollup_file)

    File.readlines(smap_rollup_file).each do |line|
      line.chomp!
      next unless line.end_with?("kB")

      key, value, _units = line.split
      key = key.chomp(":").to_sym

      stats[key] += (value.to_f * 1024).round
    end

    stats
  end

  def convert_units(value, units)
    divisor = UNIT_CONVERSION[units.to_s.downcase]
    raise ArgumentError.new("Unknown units: #{units}") unless divisor

    return value if divisor == 1

    value.to_f / divisor
  end

  def smap_rollup_file
    "/proc/#{pid}/smaps_rollup"
  end
end
