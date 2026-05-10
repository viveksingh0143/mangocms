# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MangoCMS.Repo.insert!(%MangoCMS.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias MangoCMS.Accounts
alias MangoCMS.Accounts.User
alias MangoCMS.Repo

platform_admin_email = System.get_env("PLATFORM_ADMIN_EMAIL", "platform@mangocms.local")
platform_admin_password = System.get_env("PLATFORM_ADMIN_PASSWORD")
platform_admin_name = System.get_env("PLATFORM_ADMIN_NAME", "Platform Admin")

if is_binary(platform_admin_password) and String.length(platform_admin_password) >= 8 do
  identity_key = User.identity_key("platform", nil, platform_admin_email)

  case Repo.get_by(User, identity_key: identity_key) do
    %User{} ->
      IO.puts("Platform admin already exists: #{platform_admin_email}")

    nil ->
      {:ok, _user} =
        Accounts.register_platform_user(%{
          email: platform_admin_email,
          password: platform_admin_password,
          full_name: platform_admin_name,
          timezone: "UTC",
          locale: "en"
        })

      IO.puts("Created platform admin: #{platform_admin_email}")
  end
else
  IO.puts("""
  Skipping platform admin seed.
  Set PLATFORM_ADMIN_PASSWORD to at least 8 characters, and optionally PLATFORM_ADMIN_EMAIL/PLATFORM_ADMIN_NAME.
  """)
end
