defmodule MangoCMSWeb.Brand do
  @moduledoc "Compile-time branding text used by web templates and components."

  @config Application.compile_env(:mangocms, __MODULE__, [])
  @name Keyword.get(@config, :name, "MangoCMS")
  @apple_mobile_web_app_title Keyword.get(@config, :apple_mobile_web_app_title, @name)
  @platform_profile_email Keyword.get(@config, :platform_profile_email, "platform@mangocms.local")
  @admin_profile_email Keyword.get(@config, :admin_profile_email, "admin@mangocms.local")
  @email_from Keyword.get(@config, :email_from, {@name, "noreply@mangocms.local"})
  @copyright Keyword.get(@config, :copyright, "Copyright 2026 #{@name}.")

  def name, do: @name
  def apple_mobile_web_app_title, do: @apple_mobile_web_app_title
  def platform_profile_email, do: @platform_profile_email
  def admin_profile_email, do: @admin_profile_email
  def email_from, do: @email_from
  def copyright, do: @copyright
end
