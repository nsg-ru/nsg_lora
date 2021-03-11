defmodule NsgLora.Validate do
  import NsgLoraWeb.Gettext

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
end
