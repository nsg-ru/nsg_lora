defmodule NsgLoraWeb.AdminsLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext

  @add_user_deafaults [
    add_user_hidden: true,
    err_save: "",
    err_name: "",
    err_pass: "",
    err_pass_conf: ""
  ]

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    {:ok, admins} = NsgLora.Repo.Admin.all()

    {:ok,
     assign(
       socket,
       [admins: admins, alert_hidden: true, user_to_delete: ""] ++ @add_user_deafaults
     )}
  end

  @impl true
  def handle_event("add_admin", params, socket) do
    IO.inspect(event: "AddAdmin", params: params, assigns: socket.assigns)

    case NsgLora.Repo.Admin.write(params["admin"]) do
      {:ok, _} ->
        {:ok, admins} = NsgLora.Repo.Admin.all()
        {:noreply, assign(socket, admins: admins, err_save: "", add_user_hidden: true)}

      {:error, {:transaction_aborted, err}} ->
        {:noreply, assign(socket, err_save: err)}
    end
  end

  def handle_event("add_user", _params, socket) do
    {:noreply, assign(socket, add_user_hidden: !socket.assigns.add_user_hidden)}
  end

  def handle_event("delete-user-req", %{"username" => username}, socket) do
    {:noreply, assign(socket, alert_hidden: false, user_to_delete: username)}
  end

  def handle_event("delete-user-cancel", _, socket) do
    {:noreply, assign(socket, alert_hidden: true)}
  end

  def handle_event("delete-user", %{"username" => username}, socket) do
    NsgLora.Repo.Admin.delete(username)
    {:ok, admins} = NsgLora.Repo.Admin.all()
    {:noreply, assign(socket, admins: admins, alert_hidden: true)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end
end
