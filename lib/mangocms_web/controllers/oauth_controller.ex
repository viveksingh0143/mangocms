defmodule MangoCMSWeb.OAuthController do
  use MangoCMSWeb, :controller

  alias MangoCMS.Accounts
  alias MangoCMS.Accounts.SSO
  alias MangoCMSWeb.UserAuth

  @salt "oauth-state"

  def request(conn, %{"provider" => provider}) do
    context = auth_context(conn)
    nonce = random_url_token()
    state = sign_state(conn, context, provider, nonce)
    redirect_uri = callback_url(conn, context, provider)

    case SSO.authorization_url(provider, redirect_uri, state, nonce) do
      {:ok, url} ->
        redirect(conn, external: url)

      {:error, :not_configured} ->
        conn
        |> put_flash(:error, "#{SSO.provider_label(provider)} login is not configured yet.")
        |> redirect(to: login_path(context))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Unknown SSO provider.")
        |> redirect(to: login_path(context))
    end
  end

  def callback(conn, %{"provider" => provider, "code" => code, "state" => state}) do
    with {:ok, state_data} <- verify_state(conn, state),
         true <- state_data["provider"] == provider,
         context <- auth_context_from_state(conn, state_data),
         redirect_uri <- callback_url(conn, context, provider),
         {:ok, profile} <- SSO.fetch_identity(provider, code, redirect_uri),
         {:ok, user} <- upsert_sso_user(context, profile) do
      conn
      |> put_flash(:info, "Signed in with #{SSO.provider_label(provider)}.")
      |> UserAuth.log_in_user(user)
      |> redirect(to: admin_home_path(context))
    else
      _ ->
        context = auth_context(conn)

        conn
        |> put_flash(:error, "Could not sign in with #{SSO.provider_label(provider)}.")
        |> redirect(to: login_path(context))
    end
  end

  def callback(conn, %{"provider" => provider}) do
    context = auth_context(conn)

    conn
    |> put_flash(:error, "Could not sign in with #{SSO.provider_label(provider)}.")
    |> redirect(to: login_path(context))
  end

  defp sign_state(conn, context, provider, nonce) do
    Phoenix.Token.sign(conn, @salt, %{
      "context" => context_name(context),
      "tenant_id" => tenant_id(context),
      "provider" => provider,
      "nonce" => nonce
    })
  end

  defp verify_state(conn, state), do: Phoenix.Token.verify(conn, @salt, state, max_age: 600)

  defp auth_context(conn) do
    if String.starts_with?(conn.request_path, "/platform/admin") do
      :platform
    else
      {:tenant, conn.assigns.current_tenant}
    end
  end

  defp auth_context_from_state(_conn, %{"context" => "platform"}), do: :platform

  defp auth_context_from_state(conn, %{"context" => "tenant", "tenant_id" => tenant_id}) do
    case conn.assigns[:current_tenant] do
      %{id: ^tenant_id} = tenant -> {:tenant, tenant}
      _ -> {:tenant, nil}
    end
  end

  defp upsert_sso_user(:platform, profile), do: Accounts.upsert_platform_sso_user(profile)
  defp upsert_sso_user({:tenant, nil}, _profile), do: {:error, :tenant_mismatch}

  defp upsert_sso_user({:tenant, tenant}, profile),
    do: Accounts.upsert_tenant_sso_user(tenant, profile)

  defp callback_url(conn, :platform, provider) do
    request_base_url(conn) <> ~p"/platform/admin/auth/#{provider}/callback"
  end

  defp callback_url(conn, {:tenant, _tenant}, provider) do
    request_base_url(conn) <> ~p"/admin/auth/#{provider}/callback"
  end

  defp request_base_url(conn) do
    scheme = Atom.to_string(conn.scheme)
    port = if default_port?(conn.scheme, conn.port), do: "", else: ":#{conn.port}"
    "#{scheme}://#{conn.host}#{port}"
  end

  defp default_port?(:http, 80), do: true
  defp default_port?(:https, 443), do: true
  defp default_port?(_, _), do: false

  defp login_path(:platform), do: ~p"/platform/admin/login"
  defp login_path({:tenant, _tenant}), do: ~p"/admin/login"

  defp admin_home_path(:platform), do: ~p"/platform/admin/plans"
  defp admin_home_path({:tenant, _tenant}), do: ~p"/admin/products"

  defp context_name(:platform), do: "platform"
  defp context_name({:tenant, _tenant}), do: "tenant"

  defp tenant_id(:platform), do: nil
  defp tenant_id({:tenant, tenant}), do: tenant.id

  defp random_url_token do
    16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end
end
