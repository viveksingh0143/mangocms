defmodule MangoCMSWeb.PlatformRegistration do
  @moduledoc "Runtime toggle for public platform admin registration."

  def enabled? do
    :mangocms
    |> Application.get_env(:platform_admin_registration, [])
    |> Keyword.get(:enabled, false)
  end
end
