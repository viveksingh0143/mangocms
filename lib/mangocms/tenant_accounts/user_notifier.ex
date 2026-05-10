defmodule MangoCMS.TenantAccounts.UserNotifier do
  @moduledoc "Tenant-local account notification emails."

  import Swoosh.Email

  alias MangoCMS.Mailer
  alias MangoCMS.TenantAccounts.User

  @from MangoCMSWeb.Brand.email_from()

  def deliver_confirmation_instructions(%User{} = user, url) do
    user
    |> base_email("Confirm your account")
    |> text_body("""
    Hi #{display_name(user)},

    Confirm your account by visiting:

    #{url}
    """)
    |> Mailer.deliver()
  end

  def deliver_reset_password_instructions(%User{} = user, url) do
    user
    |> base_email("Reset your password")
    |> text_body("""
    Hi #{display_name(user)},

    Reset your password by visiting:

    #{url}
    """)
    |> Mailer.deliver()
  end

  defp base_email(%User{} = user, subject) do
    new()
    |> to(user.email)
    |> from(@from)
    |> subject(subject)
  end

  defp display_name(%User{full_name: name}) when is_binary(name) and name != "", do: name
  defp display_name(%User{email: email}), do: email
end
