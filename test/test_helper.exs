Application.put_env(:mangocms, :tenant_data_root, Path.expand("tmp/tenants"))
MangoCMS.TenantTestCleanup.cleanup!()

ExUnit.start()
ExUnit.after_suite(fn _result -> MangoCMS.TenantTestCleanup.cleanup!() end)
Ecto.Adapters.SQL.Sandbox.mode(MangoCMS.Repo, :manual)
