defmodule MangoCMS.Accounts.SSO do
  @moduledoc """
  OAuth/OIDC provider helpers for Google, Microsoft Outlook, and Apple.
  """

  @providers ~w(google outlook apple)

  def providers, do: @providers

  def provider_enabled?(provider) when provider in @providers do
    config = provider_config(provider)
    present?(config[:client_id]) and present?(config[:client_secret])
  end

  def provider_enabled?(_), do: false

  def authorization_url(provider, redirect_uri, state, nonce) when provider in @providers do
    config = provider_config(provider)

    if provider_enabled?(provider) do
      query =
        %{
          client_id: config[:client_id],
          redirect_uri: redirect_uri,
          response_type: "code",
          scope: Enum.join(config[:scopes], " "),
          state: state,
          nonce: nonce
        }
        |> maybe_put(:response_mode, config[:response_mode])
        |> URI.encode_query()

      {:ok, config[:authorization_url] <> "?" <> query}
    else
      {:error, :not_configured}
    end
  end

  def authorization_url(_, _, _, _), do: {:error, :unknown_provider}

  def fetch_identity(provider, code, redirect_uri) when provider in @providers do
    config = provider_config(provider)

    with true <- provider_enabled?(provider),
         {:ok, token_response} <- exchange_code(config, code, redirect_uri),
         {:ok, claims} <- fetch_claims(provider, config, token_response) do
      normalize_claims(provider, claims, token_response)
    else
      false -> {:error, :not_configured}
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_identity(_, _, _), do: {:error, :unknown_provider}

  def provider_label("google"), do: "Google"
  def provider_label("outlook"), do: "Microsoft"
  def provider_label("apple"), do: "Apple"
  def provider_label(provider), do: String.capitalize(to_string(provider))

  defp provider_config(provider) do
    :mangocms
    |> Application.get_env(:sso, [])
    |> Keyword.get(String.to_existing_atom(provider), [])
  rescue
    ArgumentError -> []
  end

  defp exchange_code(config, code, redirect_uri) do
    body = [
      client_id: config[:client_id],
      client_secret: config[:client_secret],
      code: code,
      grant_type: "authorization_code",
      redirect_uri: redirect_uri
    ]

    case Req.post(config[:token_url], form: body, receive_timeout: 15_000) do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {:token_exchange_failed, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_claims("apple", _config, %{"id_token" => id_token}) do
    decode_jwt_payload(id_token)
  end

  defp fetch_claims(_provider, config, %{"access_token" => access_token} = token_response) do
    if present?(config[:userinfo_url]) do
      case Req.get(config[:userinfo_url], auth: {:bearer, access_token}, receive_timeout: 15_000) do
        {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
        _ -> token_response |> Map.get("id_token") |> decode_jwt_payload()
      end
    else
      token_response |> Map.get("id_token") |> decode_jwt_payload()
    end
  end

  defp fetch_claims(_provider, _config, %{"id_token" => id_token}),
    do: decode_jwt_payload(id_token)

  defp fetch_claims(_provider, _config, _token_response), do: {:error, :missing_identity_claims}

  defp normalize_claims(provider, claims, token_response) do
    provider_uid = claims["sub"] || claims["id"]

    if present?(provider_uid) do
      {:ok,
       %{
         provider: provider,
         provider_uid: provider_uid,
         email: claims["email"],
         name: claims["name"] || joined_name(claims),
         avatar_url: claims["picture"],
         raw_data: %{"claims" => claims, "token_type" => token_response["token_type"]}
       }}
    else
      {:error, :missing_provider_uid}
    end
  end

  defp joined_name(%{"given_name" => given_name, "family_name" => family_name}) do
    [given_name, family_name]
    |> Enum.filter(&present?/1)
    |> Enum.join(" ")
  end

  defp joined_name(_), do: nil

  defp decode_jwt_payload(nil), do: {:error, :missing_identity_claims}

  defp decode_jwt_payload(id_token) do
    with [_header, payload, _signature] <- String.split(id_token, "."),
         {:ok, json} <- Base.url_decode64(payload, padding: false),
         {:ok, claims} <- Jason.decode(json) do
      {:ok, claims}
    else
      _ -> {:error, :invalid_identity_token}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
