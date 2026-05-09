defmodule MangoCMSWeb.AuthTestHelpers do
  import Plug.Conn
  import Phoenix.ConnTest

  alias MangoCMS.Accounts
  alias MangoCMS.Platform.Tenant

  @password "valid-password-123"

  def valid_password, do: @password

  def platform_user_fixture(attrs \\ %{}) do
    suffix = System.unique_integer([:positive])

    attrs =
      Enum.into(attrs, %{
        email: "platform-#{suffix}@example.com",
        password: @password,
        full_name: "Platform Admin #{suffix}",
        timezone: "UTC",
        locale: "en"
      })

    {:ok, user} = Accounts.register_platform_user(attrs)
    user
  end

  def tenant_user_fixture(%Tenant{} = tenant, attrs \\ %{}) do
    suffix = System.unique_integer([:positive])

    attrs =
      Enum.into(attrs, %{
        email: "tenant-#{tenant.id}-#{suffix}@example.com",
        password: @password,
        full_name: "Tenant Admin #{suffix}",
        timezone: "UTC",
        locale: "en"
      })

    {:ok, user} = Accounts.register_tenant_user(tenant, attrs)
    user
  end

  def log_in_user(conn, user) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> init_test_session(%{})
    |> put_session(:user_token, token)
  end

  def register_and_log_in_platform_user(conn, attrs \\ %{}) do
    user = platform_user_fixture(attrs)
    {log_in_user(conn, user), user}
  end

  def register_and_log_in_tenant_user(conn, %Tenant{} = tenant, attrs \\ %{}) do
    user = tenant_user_fixture(tenant, attrs)

    conn =
      conn
      |> log_in_user(user)
      |> put_session(:tenant_id, tenant.id)

    {conn, user}
  end
end
