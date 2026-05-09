defmodule MangoCMS.TenantTestCleanup do
  @moduledoc false

  @tenant_repo_supervisor MangoCMS.TenantRepoSupervisor

  def cleanup! do
    stop_tenant_repos()
    remove_test_tenant_root()
  end

  defp stop_tenant_repos do
    if Process.whereis(@tenant_repo_supervisor) do
      @tenant_repo_supervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_id, pid, _type, _modules} -> stop_child(pid) end)
    end
  end

  defp stop_child(pid) when is_pid(pid) do
    ref = Process.monitor(pid)
    _ = DynamicSupervisor.terminate_child(@tenant_repo_supervisor, pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    after
      1_000 -> :ok
    end
  end

  defp stop_child(_), do: :ok

  defp remove_test_tenant_root do
    root =
      :mangocms
      |> Application.get_env(:tenant_data_root)
      |> to_string()
      |> Path.expand()

    if safe_test_root?(root) do
      File.rm_rf(root)
    end
  end

  defp safe_test_root?(root) do
    tmp_root = Path.expand("tmp")
    root == tmp_root or String.starts_with?(root, tmp_root <> "/")
  end
end
