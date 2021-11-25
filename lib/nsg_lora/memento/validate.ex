defmodule NsgLora.Validate do
  import NsgLoraWeb.Gettext

  def port(errmap, _id, nil), do: errmap

  def port(errmap, id, value) do
    value = String.trim(value)

    case value do
      "" ->
        errmap

      _ ->
        case Integer.parse(value) do
          {n, ""} ->
            cond do
              n <= 0 or n > 65535 -> Map.put(errmap, id, gettext("Must be from 1 to 65535"))
              true -> errmap
            end

          _ ->
            Map.put(errmap, id, gettext("Must be number"))
        end
    end
  end

  def uint(errmap, _id, nil), do: errmap

  def uint(errmap, id, value) do
    value = String.trim(value)

    case value do
      "" ->
        errmap

      _ ->
        case Integer.parse(value) do
          {n, ""} ->
            cond do
              n < 0 -> Map.put(errmap, id, gettext("Must be unsigned integer"))
              true -> errmap
            end

          _ ->
            Map.put(errmap, id, gettext("Must be number"))
        end
    end
  end

  def hex(errmap, _id, nil, _size), do: errmap

  def hex(errmap, id, value, size) do
    value = String.trim(value)

    case Integer.parse(value, 16) do
      {_, ""} ->
        case String.length(value) do
          ^size ->
            errmap

          _ ->
            Map.put(
              errmap,
              id,
              "#{ngettext("Must be", "Must be", size)} #{size} #{ngettext("char", "chars", size)}"
            )
        end

      _ ->
        Map.put(errmap, id, gettext("Must be hex number"))
    end
  end

  def hex(errmap, id, value) when is_binary(value) do
    len = value |> String.trim() |> String.length()

    case rem(len, 2) do
      0 -> errmap
      _ -> Map.put(errmap, id, gettext("Must be an even number of digits"))
    end
    |> hex(id, value, len)
  end

  def trim(errmap, id, value) when is_binary(value) do
    if value == String.trim(value) do
      errmap
    else
      Map.put(errmap, id, gettext("Must not be leading or trailing whitespaces"))
    end
  end
end
