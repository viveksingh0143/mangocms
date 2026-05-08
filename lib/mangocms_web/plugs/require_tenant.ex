defmodule MangoCMSWeb.Plugs.RequireTenant do
  @moduledoc "Halts tenant-admin HTTP requests when no tenant was resolved."

  import Plug.Conn
  import Phoenix.Controller, only: [text: 2]

  alias MangoCMS.Platform.Tenant

  def init(opts), do: opts

  def call(%{assigns: %{current_tenant: %Tenant{}}} = conn, _opts), do: conn

  def call(conn, _opts) do
    conn
    |> put_status(:not_found)
    |> text("Tenant not found")
    |> halt()
  end
end
