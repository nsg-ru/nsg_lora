defmodule NsgLoraWeb.HeaderComponent do
  use NsgLoraWeb, :live_component

  @chpsw_deafaults [
    chpsw_hidden: true,
    err_save: "",
    err_pass: "",
    err_pass_conf: "",
    username: "",
    fullname: "",
    password: "",
    password_confirm: ""
  ]

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, assign(socket, @chpsw_deafaults)}
  end

  @impl true
  def handle_event("toggle-lang", _params, socket) do
    toggle_lang(socket.assigns.admin.username)

    {:noreply, push_redirect(socket, to: socket.assigns.path)}
  end

  def handle_event("toggle-theme", _params, socket) do
    admin = toggle_theme(socket.assigns.admin.username)

    {:noreply, assign(socket, admin: admin)}
  end

  def handle_event("edit-profile", _params, socket) do
    {:noreply, assign(socket, chpsw_hidden: false, fullname: socket.assigns.admin.fullname)}
  end

  def handle_event("close-profile", _params, socket) do
    {:noreply, assign(socket, chpsw_hidden: true)}
  end

  def handle_event("admin_validate", %{"admin" => admin}, socket) do
    {_, valid} = NsgLoraWeb.AdminsLive.admin_validate(admin)

    {:noreply, assign(socket, valid)}
  end

  def handle_event("save_profile", %{"admin" => admin}, socket) do
    {res, valid} = NsgLoraWeb.AdminsLive.admin_validate(admin)

    case res do
      :error ->
        {:noreply, assign(socket, valid)}

      :ok ->
        hash =
          case admin["password"] do
            "" ->
              socket.assigns.admin.hash

            _ ->
              NsgLora.Hash.hash_pwd_salt(admin["password"])
          end

        admin = %{socket.assigns.admin | fullname: admin["fullname"], hash: hash}

        case NsgLora.Repo.Admin.write(admin) do
          {:ok, admin} ->
            Phoenix.PubSub.broadcast(
              NsgLora.PubSub,
              "system",
              {:change_admin_profile, admin.username}
            )

            {:noreply,
             assign(
               socket,
               [err_save: "", chpsw_hidden: true, admin: admin] ++ @chpsw_deafaults
             )}

          {:error, {:transaction_aborted, err}} ->
            {:noreply, assign(socket, err_save: err)}
        end
    end
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end

  def toggle_lang(username) do
    {:ok, admin} = NsgLora.Repo.Admin.read(username)
    opts = admin.opts || %{}

    lang =
      case opts[:lang] do
        "en" -> "ru"
        _ -> "en"
      end

    opts = Map.put(opts, :lang, lang)
    NsgLora.Repo.Admin.write(%{admin | opts: opts})
  end

  def toggle_theme(username) do
    {:ok, admin} = NsgLora.Repo.Admin.read(username)
    opts = admin.opts || %{}

    theme =
      case opts[:light_theme] do
        true -> false
        _ -> true
      end

    opts = Map.put(opts, :light_theme, theme)
    admin = %{admin | opts: opts}
    NsgLora.Repo.Admin.write(admin)
    admin
  end
end
