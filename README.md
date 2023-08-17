# Linux Process Memory Ruby Gem

[![Continuous Integration](https://github.com/bdurand/linux_process_memory/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/linux_process_memory/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

Ruby gem to get a breakdown of the memory being used by a Linux process. It is specific to Linux and will not work on other operating systems even if they are Linux-like (i.e. MacOS, Windows, FreeBSD, etc.). The breakdown takes into account shared memory and swap memory. It is most useful for monitoring memory usage of processes that use shared memory.

If you need similar functionality like this on other platforms, you can use the [get_process_mem gem](https://github.com/zombocom/get_process_mem).

## Usage

Pass in a process pid to get a breakdown of the memory being used by that process.

```ruby
memory = LinuxProcessMemory.new(1234)
```

If you don't pass in a pid, it will get the memory for the current process.

```ruby
memory = LinuxProcessMemory.new
```

The memory breakdown is captured at the time the object is created. To get the memory breakdown at a different time, create a new object.

Memory is complicated in Linux and there are many different ways to measure it depending on how you want to count shared memory and swap. This gem provides a few different ways to measure memory usage. The following methods are available:

```ruby
memory = LinuxProcessMemory.new
memory.total # => total memory used by the process (resident + swap)
memory.swap # => swap memory used
memory.shared # => shared memory used
memory.rss # => resident set size (i.e. non-swap memory allocated)
memory.resident # same as rss
memory.pss # => proportional set size (resident size + shared memory / number of processes)
memory.proportional # same as pss
memory.uss # => unique set size (resident memory not shared with other processes)
memory.unique # same as uss
memory.referenced # => memory actively referenced by the process (i.e. non-freeable memory)
```

These measurements tend to be the mose useful ones especially if your processes are using shared memory:

- [Resident Set Size](https://en.wikipedia.org/wiki/Resident_set_size)
- [Proportional Set Size](https://en.wikipedia.org/wiki/Proportional_set_size)
- [Unique Set Size](https://en.wikipedia.org/wiki/Unique_set_size)

Values are returned in bytes, but you can request different units by passing in an optional argument to indicate the unit. Note that requesting a unit other than bytes will return a `Float` instead of an `Integer`.

```ruby
memory = LinuxProcessMemory.new
memory.total(:kb) # => total memory used by the process in kilobytes
memory.total(:mb) # => total memory used by the process in megabytes
memory.total(:gb) # => total memory used by the process in gigabytes
```

This gem is specific to Linux. If you try to use it on a non-Linux platform then memory values will always be returned as -1. If you want to check if the gem is supported on your platform, you can use the `supported?` method.

```ruby
if LinuxProcessMemory.supported?
  memory = LinuxProcessMemory.new
end
```

### Example

Here's an example of how you might use this gem to collect memory information on your processes by logging resident memory every minute.

```ruby
if LinuxProcessMemory.supported?
  logger = Logger.new($stderr)
  Thread.new do
    loop do
      memory = LinuxProcessMemory.new
      logger.info("Proportional memory: #{memory.pss(:mb).round} MB (pid: #{Process.pid})")
      sleep(60)
    end
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "linux_process_memory"
```

Then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install linux_process_memory
```

## Contributing

Open a pull request on [GitHub](https://github.com/bdurand/linux_process_memory).

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).