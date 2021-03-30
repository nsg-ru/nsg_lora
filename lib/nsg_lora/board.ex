defmodule NsgLora.Board do
  case Mix.env() do
    :nsg17xx ->
      def init() do
        File.write("/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq", "792000")
      end

    _ ->
      def init(), do: nil
  end
end
