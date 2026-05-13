defmodule MangoCMSWeb.AdminGuard do
  @moduledoc """
  LiveView authorization helpers for admin screens.

  Role names and permission membership live in `MangoCMS.Authorization`; this
  module keeps redirect/flash behavior for admin LiveViews in one web-facing
  place.
  """

  use MangoCMSWeb, :verified_routes

  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  alias MangoCMS.Authorization

  def authorize_platform(socket, permission) do
    authorize(socket, :platform, permission, ~p"/platform/admin/dashboard")
  end

  def authorize_tenant(socket, permission) do
    authorize(socket, :tenant, permission, ~p"/admin/dashboard")
  end

  defp authorize(socket, scope, permission, redirect_path) do
    if Authorization.can?(socket.assigns[:current_user], scope, permission) do
      {:ok, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You do not have access to that admin area.")
        |> redirect(to: redirect_path)

      {:redirect, socket}
    end
  end
end
