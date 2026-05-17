defmodule MangoCMS.Authorization do
  @moduledoc """
  Central role and access policy definitions for platform and tenant users.

  Keep role names and admin gates here so CRUD surfaces, auth plugs, and UI
  links don't each grow their own definition of "admin".
  """

  @platform_roles ~w(owner admin editor viewer customer guest)
  @platform_admin_roles ~w(owner admin)

  @tenant_roles ~w(owner admin staff customer member)
  @tenant_admin_roles ~w(owner admin staff)
  @tenant_manager_roles ~w(owner admin)

  @platform_permissions %{
    access_admin: @platform_admin_roles,
    view_dashboard: @platform_admin_roles,
    manage_plans: @platform_admin_roles,
    manage_tenants: @platform_admin_roles,
    manage_users: @platform_admin_roles
  }

  @tenant_permissions %{
    access_admin: @tenant_admin_roles,
    view_dashboard: @tenant_admin_roles,
    manage_content: @tenant_admin_roles,
    manage_pages: @tenant_admin_roles,
    manage_users: @tenant_manager_roles,
    manage_settings: @tenant_manager_roles
  }

  def platform_roles, do: @platform_roles
  def tenant_roles, do: @tenant_roles

  def platform_role_options, do: role_options(@platform_roles)
  def tenant_role_options, do: role_options(@tenant_roles)

  def platform_role?(role), do: role in @platform_roles
  def tenant_role?(role), do: role in @tenant_roles

  def platform_admin_role?(role), do: role in @platform_admin_roles
  def tenant_admin_role?(role), do: role in @tenant_admin_roles
  def tenant_manager_role?(role), do: role in @tenant_manager_roles

  def can?(user, :platform, permission) do
    user_allowed?(user, @platform_permissions[permission], &platform_active_user?/1)
  end

  def can?(user, :tenant, permission) do
    user_allowed?(user, @tenant_permissions[permission], &tenant_active_user?/1)
  end

  def platform_admin_user?(%{scope: "platform", tenant_id: nil, role: role, disabled_at: nil}),
    do: role in Map.fetch!(@platform_permissions, :access_admin)

  def platform_admin_user?(_user), do: false

  def platform_active_user?(%{scope: "platform", tenant_id: nil, disabled_at: nil}), do: true
  def platform_active_user?(_user), do: false

  def tenant_admin_user?(%{role: role, disabled_at: nil}),
    do: role in Map.fetch!(@tenant_permissions, :access_admin)

  def tenant_admin_user?(_user), do: false

  def tenant_active_user?(%{disabled_at: nil}), do: true
  def tenant_active_user?(_user), do: false

  def role_label(role) when is_binary(role) do
    role
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def role_label(role), do: to_string(role)

  defp role_options(roles), do: Enum.map(roles, &{role_label(&1), &1})

  defp user_allowed?(%{role: role} = user, roles, active?) when is_list(roles) do
    active?.(user) and role in roles
  end

  defp user_allowed?(_user, _roles, _active?), do: false
end
