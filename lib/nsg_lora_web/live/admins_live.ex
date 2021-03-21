defmodule NsgLoraWeb.AdminsLive do
  use NsgLoraWeb, :live_view
  import NsgLoraWeb.Gettext

  @add_user_deafaults [
    add_user_hidden: true,
    err_save: "",
    err_name: "",
    err_pass: "",
    err_pass_conf: "",
    username: "",
    fullname: "",
    password: "",
    password_confirm: ""
  ]

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, NsgLoraWeb.Live.init(__MODULE__, session, socket))

    Phoenix.PubSub.subscribe(NsgLora.PubSub, "system")
    admins = all_admins_sorted()

    {:ok,
     assign(
       socket,
       [admins: admins, alert_hidden: true, user_to_delete: ""] ++ @add_user_deafaults
     )}
  end

  @impl true
  def handle_event("add_admin", %{"admin" => admin}, socket) do
    {res, valid} = admin_validate(admin, socket.assigns.admins)

    case res do
      :error ->
        {:noreply, assign(socket, valid)}

      :ok ->
        case NsgLora.Repo.Admin.write(admin) do
          {:ok, _} ->
            admins = all_admins_sorted()

            {:noreply,
             assign(
               socket,
               [admins: admins, err_save: "", add_user_hidden: true] ++ @add_user_deafaults
             )}

          {:error, {:transaction_aborted, err}} ->
            {:noreply, assign(socket, err_save: err)}
        end
    end
  end

  def handle_event("admin_validate", %{"admin" => admin}, socket) do
    {_, valid} = admin_validate(admin, socket.assigns.admins)

    {:noreply, assign(socket, valid)}
  end

  def handle_event("add_user", _params, socket) do
    {:noreply,
     assign(socket, add_user_hidden: !socket.assigns.add_user_hidden, alert_hidden: true)}
  end

  def handle_event("delete-user-req", %{"username" => username}, socket) do
    {:noreply, assign(socket, alert_hidden: false, user_to_delete: username)}
  end

  def handle_event("delete-user-cancel", _, socket) do
    {:noreply, assign(socket, alert_hidden: true)}
  end

  def handle_event("delete-user", %{"username" => username}, socket) do
    NsgLora.Repo.Admin.delete(username)
    admins = all_admins_sorted()
    {:noreply, assign(socket, admins: admins, alert_hidden: true)}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:change_admin_profile, _username}, socket) do
    admins = all_admins_sorted()
    {:noreply, assign(socket, admins: admins)}
  end

  def handle_info(_mes, socket) do
    {:noreply, socket}
  end


  defp is_admin_exists(admins, username) do
    admins |> Enum.find(fn %{username: n} -> n == String.trim(username) end)
  end

  defp all_admins_sorted() do
    {:ok, admins} = NsgLora.Repo.Admin.all()
    admins |> Enum.sort_by(fn %{username: u} -> u end)
  end

  def admin_validate(admin, admins \\ nil) do
    u = admin["username"]

    err_name =
      case admins do
        nil ->
          ""

        _ ->
          cond do
            String.trim(u) == "" -> gettext("Name must not be empty")
            is_admin_exists(admins, u) -> gettext("Name already exists")
            true -> ""
          end
      end

    p = admin["password"]
    pl = String.length(p)
    err_pass =
      cond do
        pl == 0 && admins -> gettext("No password")
        String.match?(p, ~r/\s/) -> gettext("Do not use spaces")
        !String.match?(p, ~r/^[\x21-\x7e]+$/) -> gettext("Use only ASCII chars")
        pl < 8 and pl != 0 -> gettext("Too short")
        true -> ""
      end

    pc = admin["password_confirm"]

    err_pass_conf =
      cond do
        p != pc -> gettext("Not equal")
        true -> ""
      end

    {if err_name <> err_pass <> err_pass_conf == "" do
       :ok
     else
       :error
     end,
     [
       err_name: err_name,
       err_pass: err_pass,
       err_pass_conf: err_pass_conf,
       username: u,
       fullname: admin["fullname"],
       password: p,
       password_confirm: pc
     ]}
  end
end
