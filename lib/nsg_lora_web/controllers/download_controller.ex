defmodule NsgLoraWeb.DownloadController do
  use NsgLoraWeb, :controller

  def export(conn, params) do
    IO.inspect(params)

    {filename, content} =
      case params["filename"] do
        "RAK7200_markers" ->
          {qty, ""} = params["params"]["qty"] |> Integer.parse()
          {"RAK7200_markers", NsgLora.LoraApps.SerRak7200.get_markers(qty)}

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
