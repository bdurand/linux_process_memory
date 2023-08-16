# frozen_string_literal: true

# This class will read the smap files for a process on a Linux system and report
# the memory usage for that process.
class LinuxProcessMemory
  # This error is raised when you try to use LinuxProcessMemory on a non-Linux system.
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
    # Returns true if the current platform is Linux.
    #
    # @return [Boolean]
    def supported?
      RUBY_PLATFORM.match?(LINUX_MATCHER)
    end
  end

  # Create a memory snapshot for the specified process.
  #
  # @param pid [Integer] The process ID to snapshot. Defaults to the current process.
  def initialize(pid = Process.pid)
    raise NotSupportedError unless self.class.supported?

    @pid = pid
    @stats = read_smaps
  end

  # Returns the total memory usage for the process.
  #
  # @param units [Symbol] The units to return the memory usage in.
  #   Valid values are :bytes, :kilobytes, :megabytes, :gigabytes, :kb, :mb, :gb, :k, :m, :g.
  #   Defaults to :bytes.
  # @return [Numberic]
  def total(units = :bytes)
    convert_units(@stats[:Rss] + @stats[:Swap], units)
  end

  # Returns the resident set size for the process.
  #
  # @param units [Symbol] The units to return the memory usage in.
  #   Valid values are :bytes, :kilobytes, :megabytes, :gigabytes, :kb, :mb, :gb, :k, :m, :g.
  #   Defaults to :bytes.
  # @return [Numberic]
  def rss(units = :bytes)
    convert_units(@stats[:Rss], units)
  end

  alias_method :resident, :rss

  # Returns the proportional set size for the process.
  #
  # @param units [Symbol] The units to return the memory usage in.
  #   Valid values are :bytes, :kilobytes, :megabytes, :gigabytes, :kb, :mb, :gb, :k, :m, :g.
  #   Defaults to :bytes.
  # @return [Numberic]
  def pss(units = :bytes)
    convert_units(@stats[:Pss], units)
  end

  alias_method :proportional, :pss

  # Returns the uniq set size for the process.
  #
  # @param units [Symbol] The units to return the memory usage in.
  #   Valid values are :bytes, :kilobytes, :megabytes, :gigabytes, :kb, :mb, :gb, :k, :m, :g.
  #   Defaults to :bytes.
  # @return [Numberic]
  def uss(units = :bytes)
    convert_units(@stats[:Private_Clean] + @stats[:Private_Dirty], units)
  end

  alias_method :unique, :uss

  # Returns the swap used by the process.
  #
  # @param units [Symbol] The units to return the memory usage in.
  #   Valid values are :bytes, :kilobytes, :megabytes, :gigabytes, :kb, :mb, :gb, :k, :m, :g.
  #   Defaults to :bytes.
  # @return [Numberic]
  def swap(units = :bytes)
    convert_units(@stats[:Swap], units)
  end

  # Returns the shared memory used by the process.
  #
  # @param units [Symbol] The units to return the memory usage in.
  #   Valid values are :bytes, :kilobytes, :megabytes, :gigabytes, :kb, :mb, :gb, :k, :m, :g.
  #   Defaults to :bytes.
  # @return [Numberic]
  def shared(units = :bytes)
    convert_units(@stats[:Shared_Clean] + @stats[:Shared_Dirty], units)
  end

  # Returns the referenced memory size for the process (i.e. memory that is actively being used)
  # that cannot be reclaimed.
  #
  # @param units [Symbol] The units to return the memory usage in.
  #   Valid values are :bytes, :kilobytes, :megabytes, :gigabytes, :kb, :mb, :gb, :k, :m, :g.
  #   Defaults to :bytes.
  # @return [Numberic]
  def referenced(units = :bytes)
    convert_units(@stats[:Referenced], units)
  end

  private

  def read_smaps
    stats = Hash.new(0)
    return stats unless File.exist?(smap_rollup_file)

    data = File.read(smap_rollup_file).split("\n")
    data.shift # remove header
    data.each do |line|
      key, value, unit = line.split
      key = key.chomp(":").to_sym

      multiplier = UNIT_CONVERSION.fetch(unit.to_s.downcase, 1)
      stats[key] += (value.to_f * multiplier).round
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
