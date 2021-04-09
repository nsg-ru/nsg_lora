defmodule NsgLoraWeb.DownloadController do
  use NsgLoraWeb, :controller

  def export(conn, params) do
    {filename, content} =
      case params["filename"] do
        "RAK7200_markers" ->
          {first, ""} = params["params"]["first"] |> Integer.parse()
          {last, ""} = params["params"]["last"] |> Integer.parse()

          markers =
            NsgLora.LoraApps.SerRak7200.get_markers(:all)
            |> Enum.filter(fn %{id: id} -> id >= first && id < last end)

          {"RAK7200_markers", markers}

        _ ->
          {"unknown", "Unknown data"}
      end

    {ext, content} =
      case params["ext"] do
        "json" ->
          case Jason.encode(content, pretty: true) do
            {:ok, content} -> {"json", content}
            {:error, err} -> {"txt", inspect(err, pretty: true)}
          end

        _ ->
          {"txt", inspect(content, pretty: true)}
      end

    conn
    |> send_download({:binary, content},
      filename:
        filename <>
          "_" <>
          (NaiveDateTime.utc_now() |> to_string() |> String.replace(" ", "_")) <> "." <> ext
    )
  end
end
