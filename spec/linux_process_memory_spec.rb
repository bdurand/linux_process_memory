# frozen_string_literal: true

require_relative "spec_helper"

describe LinuxProcessMemory do
  let(:smaps_rollup) { File.readlines(File.expand_path("fixtures/smaps_rollup.txt", __dir__)) }

  describe "detecting Linux" do
    it "detects Linux from the Ruby platform" do
      stub_const("RUBY_PLATFORM", "x86_64-linux")
      expect(LinuxProcessMemory.supported?).to be true
    end

    it "detects if not on a Linux platform" do
      stub_const("RUBY_PLATFORM", "x86_64-darwin")
      expect(LinuxProcessMemory.supported?).to be false
    end
  end

  describe "when not using Linux" do
    it "raises an error if not using Linux" do
      expect(LinuxProcessMemory).to receive(:supported?).and_return(false)
      expect { LinuxProcessMemory.new }.to raise_error(LinuxProcessMemory::NotSupportedError)
    end
  end

  describe "getting the memory usage of a process" do
    before do
      allow(LinuxProcessMemory).to receive(:supported?).and_return(true)
    end

    it "gets the memory usage of a process by pid" do
      pid = rand(10000)
      expect(File).to receive(:exist?).with("/proc/#{pid}/smaps_rollup").and_return(true)
      expect(File).to receive(:readlines).with("/proc/#{pid}/smaps_rollup").and_return(smaps_rollup)
      memory = LinuxProcessMemory.new(pid)
    end

    it "get the memory usage of the current process by default" do
      expect(File).to receive(:exist?).with("/proc/#{Process.pid}/smaps_rollup").and_return(true)
      expect(File).to receive(:readlines).with("/proc/#{Process.pid}/smaps_rollup").and_return(smaps_rollup)
      memory = LinuxProcessMemory.new
    end

    it "returns all zeroes if the process does not exist" do
      memory = LinuxProcessMemory.new(-1)
      expect(memory.total).to eq(0)
      expect(memory.rss).to eq(0)
      expect(memory.pss).to eq(0)
      expect(memory.uss).to eq(0)
      expect(memory.swap).to eq(0)
      expect(memory.shared).to eq(0)
      expect(memory.referenced).to eq(0)
    end
  end

  describe "memory breakdown" do
    before do
      allow(LinuxProcessMemory).to receive(:supported?).and_return(true)
      allow(File).to receive(:exist?).with("/proc/#{Process.pid}/smaps_rollup").and_return(true)
      allow(File).to receive(:readlines).with("/proc/#{Process.pid}/smaps_rollup").and_return(smaps_rollup)
    end

    let(:memory) { LinuxProcessMemory.new }

    it "gets the total memory used" do
      expect(memory.total).to eq((1200 + 100) * 1024)
    end

    it "gets the resident set size" do
      expect(memory.rss).to eq(1200 * 1024)
      expect(memory.rss).to eq(memory.resident)
    end

    it "gets the proportional set size" do
      expect(memory.pss).to eq(653 * 1024)
      expect(memory.pss).to eq(memory.proportional)
    end

    it "gets the unique set size" do
      expect(memory.uss).to eq((216 + 140) * 1024)
      expect(memory.uss).to eq(memory.unique)
    end

    it "gets the swap used" do
      expect(memory.swap).to eq(100 * 1024)
    end

    it "gets the shared memory used" do
      expect(memory.shared).to eq((844 + 10) * 1024)
    end

    it "gets the reference memory used" do
      expect(memory.referenced).to eq(1100 * 1024)
    end

    it "gets converts values to kilobytes" do
      expect(memory.total("kilobytes")).to eq(1200 + 100)
      expect(memory.rss("kilobytes")).to eq(1200)
      expect(memory.pss("kilobytes")).to eq(653)
      expect(memory.uss("kilobytes")).to eq(216 + 140)
      expect(memory.swap("kilobytes")).to eq(100)
      expect(memory.shared("K")).to eq(844 + 10)
      expect(memory.referenced(:Kb)).to eq(1100)
    end

    it "converts values to megabytes" do
      expect(memory.total("megabytes")).to eq((1200 + 100) / 1024.0)
      expect(memory.rss("megabytes")).to eq(1200 / 1024.0)
      expect(memory.pss("megabytes")).to eq(653 / 1024.0)
      expect(memory.uss("megabytes")).to eq((216 + 140) / 1024.0)
      expect(memory.swap("megabytes")).to eq(100 / 1024.0)
      expect(memory.shared("M")).to eq((844 + 10) / 1024.0)
      expect(memory.referenced(:Mb)).to eq(1100 / 1024.0)
    end

    it "converts values to gigabytes" do
      expect(memory.total("gigabytes")).to eq((1200 + 100) / 1024.0**2)
      expect(memory.rss("gigabytes")).to eq(1200 / 1024.0**2)
      expect(memory.pss("gigabytes")).to eq(653 / 1024.0**2)
      expect(memory.uss("gigabytes")).to eq((216 + 140) / 1024.0**2)
      expect(memory.swap("gigabytes")).to eq(100 / 1024.0**2)
      expect(memory.shared("G")).to eq((844 + 10) / 1024.0**2)
      expect(memory.referenced(:Gb)).to eq(1100 / 1024.0**2)
    end
  end

  if LinuxProcessMemory.supported?
    describe "actually do it" do
      memory = LinuxProcessMemory.new
      expect(memory.total).to be > 0
      expect(memory.rss).to be > 0
      expect(memory.uss).to be > 0
      expect(memory.pss).to be > 0
    end
  end
end
