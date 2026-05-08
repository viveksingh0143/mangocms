defmodule MangoCMSWeb.Plugs.RequirePlatformHost do
  @moduledoc "Halts platform-admin requests when the host resolves to a tenant."

  import Plug.Conn
  import Phoenix.Controller, only: [text: 2]

  alias MangoCMS.Platform.Tenant

  def init(opts), do: opts

  def call(%{assigns: %{current_tenant: %Tenant{}}} = conn, _opts) do
    conn
    |> put_status(:not_found)
    |> text("Not found")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
