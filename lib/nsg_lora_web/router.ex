defmodule NsgLoraWeb.Router do
  use NsgLoraWeb, :router

  import NsgLora.Repo.Admin, only: [load_current_admin: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NsgLoraWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug NsgLora.Pipeline
    plug :load_current_admin
  end

  # We use ensure_auth to fail if there is no one logged in
  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", NsgLoraWeb do
    pipe_through [:browser, :auth]

    get "/login", SessionController, :new
    post "/login", SessionController, :login
    get "/logout", SessionController, :logout
    get "/download", DownloadController, :export
  end

  scope "/", NsgLoraWeb do
    pipe_through [:browser, :auth, :ensure_auth]

    live "/", DashboardLive
    live "/bs", BSLive
    live "/lws", LorawanServerLive
    live "/mqtt", MQTTServerLive
    live "/absys", AboutSystemLive
    live "/admins", AdminsLive
    live "/map", MapLive
    live "/plan", PlanLive
    live "/blank", BlankLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", NsgLoraWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test, :prod] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/live_dashboard", metrics: NsgLoraWeb.Telemetry
    end
  end
end
