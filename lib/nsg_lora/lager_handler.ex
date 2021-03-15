defmodule LagerHandler do
  use Bitwise

  @behaviour :gen_event

  def init(opts) do
    config = Keyword.get(opts, :level, :debug)

    case config_to_mask(config) do
      {:ok, mask} ->
        {:ok, %{mask: mask}}

      {:error, reason} ->
        {:error, {:fatal, reason}}
    end
  end

  def handle_event({:log, lager_msg}, state) do
    metadata = :lager_msg.metadata(lager_msg)

    case metadata[:application] do
      :lorawan_server ->
        level = :lager_msg.severity(lager_msg)
        date = timestamp(:lager_msg.timestamp(lager_msg), false)
        msg = :lager_msg.message(lager_msg) |> to_string()
        NsgLora.LagerRing.log("#{date} [#{level}] #{msg}")

      _ ->
        nil
    end

    {:ok, state}
  end

  def handle_call(:get_loglevel, state) do
    {:ok, state.mask, state}
  end

  def handle_call({:set_loglevel, config}, state) do
    case config_to_mask(config) do
      {:ok, mask} ->
        {:ok, :ok, %{state | mask: mask}}

      {:error, _reason} = error ->
        {:ok, error, state}
    end
  end

  def handle_call(:get_data, state) do
    {:ok, CircularBuffer.to_list(state.data), state}
  end

  def handle_info(_msg, state) do
    {:ok, state}
  end

  def terminate(_reason, _state), do: :ok

  def code_change(_old, state, _extra), do: {:ok, state}

  defp config_to_mask(config) do
    try do
      :lager_util.config_to_mask(config)
    catch
      _, _ ->
        {:error, {:bad_log_level, config}}
    else
      mask ->
        {:ok, mask}
    end
  end

  defp timestamp(now, utc_log?) do
    {_, _, micro} = now

    {{_year, _month, _day}, {hour, minute, second}} =
      case utc_log? do
        true -> :calendar.now_to_universal_time(now)
        false -> :calendar.now_to_local_time(now)
      end

    List.flatten(
      :io_lib.format("~2..0w:~2..0w:~2..0w.~3..0w", [
        hour,
        minute,
        second,
        div(micro, 1000)
      ])
    )
    |> to_string()
  end
end
