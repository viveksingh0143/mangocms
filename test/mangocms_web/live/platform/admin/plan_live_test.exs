defmodule MangoCMSWeb.Platform.Admin.PlanLiveTest do
  use MangoCMSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MangoCMS.Platform

  @create_attrs %{
    name: "growth",
    display_name: "Growth",
    description: "For growing teams",
    price_monthly: 99900,
    price_yearly: 9_99000,
    currency: "INR",
    yearly_discount_bps: 1500,
    trial_period_days: 14,
    max_pages: 100,
    max_storage_mb: 5000,
    max_api_calls_per_day: 10_000,
    max_users: 5,
    max_domains: 3,
    max_media_files: 1000,
    active: true,
    is_public: true,
    sort_order: 1
  }

  @update_attrs %{
    name: "scale",
    display_name: "Scale",
    description: "For scaling teams",
    price_monthly: 1_99900,
    price_yearly: 19_99000,
    currency: "USD",
    yearly_discount_bps: 2000,
    trial_period_days: 30,
    max_pages: 250,
    max_storage_mb: 10_000,
    max_api_calls_per_day: 25_000,
    max_users: 10,
    max_domains: 5,
    max_media_files: 2500,
    active: true,
    is_public: false,
    sort_order: 2
  }

  @invalid_attrs %{
    name: nil,
    display_name: nil,
    price_monthly: -1,
    price_yearly: -1,
    currency: "INR"
  }

  defp plan_fixture(attrs \\ %{}) do
    {:ok, plan} =
      attrs
      |> Enum.into(@create_attrs)
      |> Platform.create_plan()

    plan
  end

  setup %{conn: conn} do
    {conn, user} = register_and_log_in_platform_user(conn)
    %{conn: conn, platform_user: user}
  end

  describe "Index" do
    test "lists all plans", %{conn: conn} do
      plan = plan_fixture()
      {:ok, _index_live, html} = live(conn, ~p"/platform/admin/plans")

      assert html =~ "Platform plans"
      assert html =~ plan.display_name
    end

    test "saves new plan", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/plans")

      assert index_live |> element("#new-plan-button") |> render_click() =~ "New plan"

      assert index_live
             |> form("#plan-form", plan: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#plan-form", plan: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/platform/admin/plans")
      assert render(index_live) =~ "Growth"
    end

    test "updates plan in listing", %{conn: conn} do
      plan = plan_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/plans")

      assert index_live |> element("#edit-plan-#{plan.id}") |> render_click() =~ "Edit plan"

      assert index_live
             |> form("#plan-form", plan: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#plan-form", plan: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/platform/admin/plans")
      html = render(index_live)
      assert html =~ "Scale"
      refute html =~ "Growth"
    end

    test "deletes plan in listing", %{conn: conn} do
      plan = plan_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/platform/admin/plans")

      assert index_live |> element("#delete-plan-#{plan.id}") |> render_click()
      refute has_element?(index_live, "#plans-#{plan.id}")
    end
  end

  describe "Show" do
    test "displays plan", %{conn: conn} do
      plan = plan_fixture()
      {:ok, _show_live, html} = live(conn, ~p"/platform/admin/plans/#{plan}")

      assert html =~ plan.display_name
      assert html =~ "Pricing"
    end

    test "updates plan within show", %{conn: conn} do
      plan = plan_fixture()
      {:ok, show_live, _html} = live(conn, ~p"/platform/admin/plans/#{plan}")

      assert show_live |> element("#edit-plan-button") |> render_click() =~ "Edit plan"

      assert show_live
             |> form("#plan-form", plan: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/platform/admin/plans/#{plan}")
      assert render(show_live) =~ "Scale"
    end
  end
end
