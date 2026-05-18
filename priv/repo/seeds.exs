alias MangoCMS.ContentTree
alias MangoCMS.Platform
alias MangoCMS.Platform.Accounts
alias MangoCMS.Platform.Accounts.User, as: PlatformUser
alias MangoCMS.Repo
alias MangoCMS.Tenant.Accounts, as: TenantAccounts
alias MangoCMS.Tenant.Collections
alias MangoCMS.Tenant.Migrator, as: TenantMigrator
alias MangoCMS.Tenant.Pages
alias MangoCMS.Tenant.RepoManager, as: TenantRepoManager
alias MangoCMS.Tenant.Settings, as: TenantSettings

defmodule MangoCMS.Seeds.Faker do
  @moduledoc false

  @first_names ~w(Aditi Arjun Kabir Maya Neha Omar Priya Rahul Riya Sana Tara Vivek)
  @last_names ~w(Sharma Mehta Iyer Rao Nair Khan Kapoor Singh Patel Das)
  @companies ["Acme Studio", "Northstar Labs", "Copper Leaf", "Pixel Foundry", "Brightlane"]
  @services [
    "Company Profile Website",
    "AI Chat Add-on",
    "Product Feature Microsite",
    "Resume Website",
    "Founder Blog",
    "Customer Story Hub"
  ]

  def company_name do
    module = Module.concat(["Faker", "Company"])

    if Code.ensure_loaded?(module) and function_exported?(module, :name, 0) do
      apply(module, :name, [])
    else
      Enum.random(@companies)
    end
  end

  def person_name do
    module = Module.concat(["Faker", "Person"])

    cond do
      Code.ensure_loaded?(module) and function_exported?(module, :name, 0) ->
        apply(module, :name, [])

      true ->
        "#{Enum.random(@first_names)} #{Enum.random(@last_names)}"
    end
  end

  def email(name, domain) do
    local =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{local}@#{domain}"
  end

  def service_name, do: Enum.random(@services)

  def sentence(topic) do
    "#{topic} for teams that want fast pages, simple editing, and tenant-isolated content."
  end
end

IO.puts("Seeding MangoCMS platform and tenant demo data...")

seed_password =
  System.get_env("SEED_PASSWORD") ||
    if(Mix.env() == :prod, do: nil, else: "P@ssw0rd123")

valid_password? = fn value -> is_binary(value) and String.length(value) >= 8 end

print_changeset_errors = fn label, changeset ->
  errors =
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)

  IO.puts("#{label}: #{inspect(errors)}")
end

confirm_platform_user = fn
  %PlatformUser{confirmed_at: nil} = user ->
    user
    |> Ecto.Changeset.change(confirmed_at: DateTime.utc_now(:second))
    |> Repo.update!()

  user ->
    user
end

upsert_platform_user = fn attrs ->
  identity_key = PlatformUser.identity_key("platform", nil, attrs.email)
  attrs = Map.put_new(attrs, :password, seed_password)

  case Repo.get_by(PlatformUser, identity_key: identity_key) do
    nil ->
      if valid_password?.(attrs.password) do
        case Accounts.create_user(attrs) do
          {:ok, user} ->
            confirm_platform_user.(user)
            IO.puts("Created platform #{attrs.role}: #{attrs.email}")

          {:error, changeset} ->
            print_changeset_errors.("Could not create platform user #{attrs.email}", changeset)
        end
      else
        IO.puts("Skipping platform user #{attrs.email}; set SEED_PASSWORD to at least 8 chars.")
      end

    user ->
      attrs = Map.drop(attrs, [:password])

      case Accounts.update_user(user, attrs) do
        {:ok, user} ->
          confirm_platform_user.(user)
          IO.puts("Updated platform #{attrs.role}: #{attrs.email}")

        {:error, changeset} ->
          print_changeset_errors.("Could not update platform user #{attrs.email}", changeset)
      end
  end
end

upsert_plan = fn attrs ->
  case Platform.get_plan_by_name(attrs.name) do
    nil ->
      case Platform.create_plan(attrs) do
        {:ok, plan} ->
          IO.puts("Created plan: #{plan.display_name}")
          plan

        {:error, changeset} ->
          print_changeset_errors.("Could not create plan #{attrs.name}", changeset)
          nil
      end

    plan ->
      case Platform.update_plan(plan, attrs) do
        {:ok, plan} ->
          IO.puts("Updated plan: #{plan.display_name}")
          plan

        {:error, changeset} ->
          print_changeset_errors.("Could not update plan #{attrs.name}", changeset)
          plan
      end
  end
end

upsert_platform_user.(%{
  email: System.get_env("PLATFORM_OWNER_EMAIL", "owner@mangocms.local"),
  full_name: System.get_env("PLATFORM_OWNER_NAME", "Platform Owner"),
  role: "owner",
  locale: "en",
  timezone: "Asia/Kolkata"
})

upsert_platform_user.(%{
  email: System.get_env("PLATFORM_ADMIN_EMAIL", "admin@mangocms.local"),
  full_name: System.get_env("PLATFORM_ADMIN_NAME", "Platform Admin"),
  role: "admin",
  locale: "en",
  timezone: "Asia/Kolkata"
})

upsert_platform_user.(%{
  email: System.get_env("PLATFORM_CUSTOMER_EMAIL", "customer@mangocms.local"),
  full_name: System.get_env("PLATFORM_CUSTOMER_NAME", "Demo Customer"),
  role: "customer",
  locale: "en",
  timezone: "Asia/Kolkata"
})

plans = [
  %{
    name: "starter",
    display_name: "Starter",
    description: "Launch a company site, blog, resume, or product page with core CMS tools.",
    active: true,
    is_public: true,
    price_monthly: 99900,
    price_yearly: 999_000,
    currency: "INR",
    yearly_discount_bps: 1667,
    trial_period_days: 14,
    trial_requires_card: false,
    max_pages: 25,
    max_storage_mb: 1024,
    max_api_calls_per_day: 5_000,
    max_users: 3,
    max_domains: 1,
    max_media_files: 500,
    features: %{
      "ai_chat" => true,
      "blog" => true,
      "company_profile" => true,
      "product_features" => true,
      "resume" => true
    },
    custom_domain_support: false,
    api_access: false,
    priority_support: false,
    white_label: false,
    sort_order: 10
  },
  %{
    name: "pro",
    display_name: "Pro",
    description: "More sites, users, domains, media, and content collections for growing teams.",
    active: true,
    is_public: true,
    price_monthly: 249_900,
    price_yearly: 2_499_000,
    currency: "INR",
    yearly_discount_bps: 1667,
    trial_period_days: 14,
    trial_requires_card: false,
    max_pages: 250,
    max_storage_mb: 10_240,
    max_api_calls_per_day: 50_000,
    max_users: 15,
    max_domains: 3,
    max_media_files: 5_000,
    features: %{
      "ai_chat" => true,
      "analytics" => true,
      "blog" => true,
      "company_profile" => true,
      "custom_domain" => true,
      "product_features" => true,
      "resume" => true
    },
    custom_domain_support: true,
    api_access: true,
    priority_support: false,
    white_label: false,
    sort_order: 20
  },
  %{
    name: "enterprise",
    display_name: "Enterprise",
    description: "White-label tenant operations with higher limits and priority support.",
    active: true,
    is_public: true,
    price_monthly: 999_900,
    price_yearly: 9_999_000,
    currency: "INR",
    yearly_discount_bps: 1667,
    trial_period_days: 30,
    trial_requires_card: true,
    max_pages: 2_500,
    max_storage_mb: 102_400,
    max_api_calls_per_day: 500_000,
    max_users: 100,
    max_domains: 25,
    max_media_files: 50_000,
    features: %{
      "ai_chat" => true,
      "analytics" => true,
      "blog" => true,
      "company_profile" => true,
      "custom_domain" => true,
      "exports" => true,
      "product_features" => true,
      "resume" => true,
      "sso" => true
    },
    custom_domain_support: true,
    api_access: true,
    priority_support: true,
    white_label: true,
    sort_order: 30
  }
]

[starter_plan | _] = Enum.map(plans, upsert_plan)

tenant_owner_email = System.get_env("TENANT_OWNER_EMAIL", "owner@acme.localhost")
tenant_owner_name = System.get_env("TENANT_OWNER_NAME", "Acme Owner")

tenant_attrs = %{
  name: System.get_env("TENANT_NAME", "Acme Studio"),
  domain: System.get_env("TENANT_DOMAIN", "acme.localhost"),
  subdomain: System.get_env("TENANT_SUBDOMAIN", "acme"),
  slug: System.get_env("TENANT_SLUG", "acme"),
  status: "active",
  active: true,
  plan_id: starter_plan.id
}

tenant =
  case Platform.get_tenant_by_subdomain_with_plan(tenant_attrs.subdomain) do
    nil ->
      create_attrs =
        if valid_password?.(seed_password) do
          Map.merge(tenant_attrs, %{
            owner_email: tenant_owner_email,
            owner_password: seed_password,
            owner_full_name: tenant_owner_name
          })
        else
          tenant_attrs
        end

      case Platform.create_tenant(create_attrs) do
        {:ok, tenant} ->
          IO.puts("Created tenant: #{tenant.name}")
          Platform.get_tenant_with_plan!(tenant.id)

        {:error, changeset} ->
          print_changeset_errors.("Could not create tenant #{tenant_attrs.slug}", changeset)
          nil
      end

    tenant ->
      case Platform.update_tenant(tenant, tenant_attrs) do
        {:ok, tenant} ->
          IO.puts("Updated tenant: #{tenant.name}")
          Platform.get_tenant_with_plan!(tenant.id)

        {:error, changeset} ->
          print_changeset_errors.("Could not update tenant #{tenant_attrs.slug}", changeset)
          tenant
      end
  end

if tenant do
  TenantMigrator.migrate_tenant!(tenant)

  confirm_tenant_user = fn user ->
    TenantRepoManager.with_repo(tenant, fn repo ->
      case user.confirmed_at do
        nil ->
          user
          |> Ecto.Changeset.change(confirmed_at: DateTime.utc_now(:second))
          |> repo.update!()

        _confirmed_at ->
          user
      end
    end)
  end

  upsert_tenant_user = fn attrs ->
    attrs = Map.put_new(attrs, :password, seed_password)

    case TenantAccounts.get_user_by_email(tenant, attrs.email) do
      nil ->
        if valid_password?.(attrs.password) do
          case TenantAccounts.create_user(tenant, attrs) do
            {:ok, user} ->
              confirm_tenant_user.(user)
              IO.puts("Created tenant #{attrs.role}: #{attrs.email}")

            {:error, changeset} ->
              print_changeset_errors.("Could not create tenant user #{attrs.email}", changeset)
          end
        end

      user ->
        attrs = Map.drop(attrs, [:password])

        case TenantAccounts.update_user(tenant, user, attrs) do
          {:ok, user} ->
            confirm_tenant_user.(user)
            IO.puts("Updated tenant #{attrs.role}: #{attrs.email}")

          {:error, changeset} ->
            print_changeset_errors.("Could not update tenant user #{attrs.email}", changeset)
        end
    end
  end

  upsert_tenant_user.(%{
    email: tenant_owner_email,
    full_name: tenant_owner_name,
    role: "owner",
    locale: "en",
    timezone: "Asia/Kolkata"
  })

  upsert_tenant_user.(%{
    email: "admin@#{tenant.domain}",
    full_name: "Acme Admin",
    role: "admin",
    locale: "en",
    timezone: "Asia/Kolkata"
  })

  upsert_tenant_user.(%{
    email: "member@#{tenant.domain}",
    full_name: "Acme Member",
    role: "member",
    locale: "en",
    timezone: "Asia/Kolkata"
  })

  settings = TenantSettings.get_or_create_site_settings!(tenant)

  {:ok, _settings} =
    TenantSettings.update_site_settings(tenant, settings, %{
      site_name: tenant.name,
      tagline: "Company sites, blogs, product pages, resumes, and site-aware AI chat.",
      support_email: "support@#{tenant.domain}",
      logo_url: "/images/logo.png",
      dark_logo_url: "/images/logo.png",
      locale: "en",
      timezone: "Asia/Kolkata"
    })

  services = [
    {"classic-3l-pressure-cooker", "Classic 3L Pressure Cooker", 249_900},
    {"family-5l-pressure-cooker", "Family 5L Pressure Cooker", 349_900},
    {"induction-5l-pressure-cooker", "Induction 5L Pressure Cooker", 399_900},
    {"hard-anodized-3l-pressure-cooker", "Hard Anodized 3L Pressure Cooker", 429_900},
    {"stainless-steel-7l-pressure-cooker", "Stainless Steel 7L Pressure Cooker", 549_900}
  ]

  upsert_collection = fn attrs, fields ->
    collection =
      case Collections.get_collection_by_slug(tenant, attrs.slug) do
        nil ->
          case Collections.create_collection(tenant, attrs) do
            {:ok, collection} ->
              collection

            {:error, changeset} ->
              print_changeset_errors.("Could not create #{attrs.slug}", changeset)
              nil
          end

        collection ->
          case Collections.update_collection(tenant, collection, attrs) do
            {:ok, collection} ->
              collection

            {:error, changeset} ->
              print_changeset_errors.("Could not update #{attrs.slug}", changeset)
              collection
          end
      end

    if collection do
      existing_fields =
        tenant
        |> Collections.list_collection_fields(collection)
        |> Map.new(&{&1.field_key, &1})

      Enum.each(fields, fn field_attrs ->
        case Map.get(existing_fields, field_attrs.field_key) do
          nil -> Collections.create_collection_field(tenant, collection, field_attrs)
          field -> Collections.update_collection_field(tenant, field, field_attrs)
        end
        |> case do
          {:ok, _field} ->
            :ok

          {:error, changeset} ->
            print_changeset_errors.("Could not seed field #{field_attrs.field_key}", changeset)
        end
      end)
    end

    collection
  end

  upsert_entry = fn collection, attrs ->
    case Collections.get_entry_by_slug(tenant, collection, attrs.slug) do
      nil -> Collections.create_entry(tenant, collection, attrs)
      entry -> Collections.update_entry(tenant, entry, attrs)
    end
    |> case do
      {:ok, entry} ->
        {:ok, entry} = Collections.publish_entry(tenant, entry)
        entry

      {:error, changeset} ->
        print_changeset_errors.("Could not seed entry #{attrs.slug}", changeset)
        nil
    end
  end

  category_collection =
    upsert_collection.(
      %{
        name: "Product Categories",
        slug: "product_categories",
        description: "Category collection for catalog taxonomy and category pages.",
        status: "active",
        archetype: "category",
        item_mode: "multiple",
        environment: "live",
        settings: %{"icon" => "tag"}
      },
      [
        %{
          label: "Title",
          field_key: "title",
          field_type: "string",
          required: true,
          primary: true,
          indexed: true,
          filterable: true,
          sortable: true,
          position: 10,
          settings: %{"slug_source" => "true"}
        },
        %{
          label: "Description",
          field_key: "description",
          field_type: "text",
          indexed: true,
          position: 20
        },
        %{label: "Image", field_key: "image_url", field_type: "image", position: 30}
      ]
    )

  category_entries =
    if category_collection do
      [
        {"stainless-steel", "Stainless Steel", "Durable steel cookers for everyday cooking."},
        {"hard-anodized", "Hard Anodized", "Premium dark finish cookers with even heating."},
        {"induction-ready", "Induction Ready", "Cookers designed for induction and gas stoves."}
      ]
      |> Enum.map(fn {slug, title, description} ->
        entry =
          upsert_entry.(category_collection, %{
            title: title,
            slug: slug,
            payload: %{
              "title" => title,
              "description" => description,
              "image_url" => "/images/logo.png"
            }
          })

        {slug, entry && entry.id}
      end)
      |> Map.new()
    else
      %{}
    end

  service_type =
    upsert_collection.(
      %{
        name: "Product Pressure Cooker",
        slug: "pressure_cookers",
        description:
          "Catalog collection for pressure cooker products and dynamic product sections.",
        status: "active",
        archetype: "catalog",
        item_mode: "multiple",
        environment: "live",
        settings: %{"catalog_type" => "deliverable", "icon" => "shopping-bag"}
      },
      [
        %{
          label: "Name",
          field_key: "name",
          field_type: "string",
          required: true,
          indexed: true,
          sortable: true,
          position: 10
        },
        %{
          label: "Price",
          field_key: "price",
          field_type: "number",
          required: true,
          indexed: true,
          filterable: true,
          sortable: true,
          position: 20
        },
        %{
          label: "Category",
          field_key: "category",
          field_type: "category",
          indexed: true,
          filterable: true,
          position: 22,
          settings: %{
            "category_collection_id" => category_collection && category_collection.id
          }
        },
        %{
          label: "SKU",
          field_key: "sku",
          field_type: "string",
          indexed: true,
          filterable: true,
          position: 25
        },
        %{
          label: "Rating",
          field_key: "rating",
          field_type: "number",
          indexed: true,
          filterable: true,
          sortable: true,
          position: 30
        },
        %{
          label: "In Stock",
          field_key: "in_stock",
          field_type: "boolean",
          indexed: true,
          filterable: true,
          position: 40
        },
        %{label: "Image URL", field_key: "image_url", field_type: "image", position: 50},
        %{
          label: "Capacity",
          field_key: "capacity",
          field_type: "string",
          indexed: true,
          filterable: true,
          position: 55
        },
        %{
          label: "Description",
          field_key: "description",
          field_type: "rich_text",
          indexed: true,
          position: 60
        }
      ]
    )

  if service_type do
    Enum.with_index(services, 1)
    |> Enum.each(fn {{slug, name, price}, index} ->
      category_slug =
        cond do
          String.contains?(slug, "stainless") -> "stainless-steel"
          String.contains?(slug, "anodized") -> "hard-anodized"
          true -> "induction-ready"
        end

      upsert_entry.(service_type, %{
        title: name,
        slug: slug,
        payload: %{
          "name" => name,
          "price" => price,
          "category" => Map.get(category_entries, category_slug),
          "sku" => "PC-#{index}-#{String.upcase(String.slice(slug, 0, 3))}",
          "rating" => Float.round(4.4 + index / 10, 1),
          "in_stock" => true,
          "image_url" => "/images/logo.png",
          "capacity" => Regex.run(~r/\d+L/, name) |> List.wrap() |> List.first() || "5L",
          "description" =>
            "#{name} is seeded as a catalog item with price, SKU, capacity, and stock fields."
        }
      })
    end)
  end

  review_type =
    upsert_collection.(
      %{
        name: "Customer Reviews",
        slug: "customer_reviews",
        description: "Customer proof and testimonial entries.",
        status: "active",
        settings: %{"icon" => "star"}
      },
      [
        %{
          label: "Customer Name",
          field_key: "customer_name",
          field_type: "string",
          required: true,
          indexed: true,
          sortable: true,
          position: 10
        },
        %{
          label: "Company",
          field_key: "company",
          field_type: "string",
          indexed: true,
          position: 20
        },
        %{
          label: "Rating",
          field_key: "rating",
          field_type: "number",
          required: true,
          indexed: true,
          filterable: true,
          sortable: true,
          position: 30
        },
        %{
          label: "Quote",
          field_key: "quote",
          field_type: "text",
          required: true,
          indexed: true,
          position: 40
        },
        %{
          label: "Reviewed At",
          field_key: "reviewed_at",
          field_type: "datetime",
          indexed: true,
          filterable: true,
          sortable: true,
          position: 50
        }
      ]
    )

  if review_type do
    Enum.each(1..6, fn index ->
      name = MangoCMS.Seeds.Faker.person_name()
      company = MangoCMS.Seeds.Faker.company_name()

      upsert_entry.(review_type, %{
        title: "#{name} Review",
        slug: "review-#{index}",
        payload: %{
          "customer_name" => name,
          "company" => company,
          "rating" => if(index <= 4, do: 5, else: 4),
          "quote" =>
            "#{company} launched a sharper tenant website and kept updates inside the CMS.",
          "reviewed_at" =>
            DateTime.utc_now(:second)
            |> DateTime.add(-index * 86_400, :second)
            |> DateTime.to_iso8601()
        }
      })
    end)
  end

  blog_type =
    upsert_collection.(
      %{
        name: "Blog Posts",
        slug: "blog_posts",
        description: "Blog articles for tenant sites.",
        status: "active",
        settings: %{"icon" => "document-text"}
      },
      [
        %{
          label: "Title",
          field_key: "title",
          field_type: "string",
          required: true,
          indexed: true,
          sortable: true,
          position: 10
        },
        %{
          label: "Excerpt",
          field_key: "excerpt",
          field_type: "text",
          required: true,
          indexed: true,
          position: 20
        },
        %{
          label: "Author",
          field_key: "author",
          field_type: "string",
          indexed: true,
          filterable: true,
          position: 30
        },
        %{
          label: "Published At",
          field_key: "published_at",
          field_type: "datetime",
          indexed: true,
          filterable: true,
          sortable: true,
          position: 40
        }
      ]
    )

  if blog_type do
    Enum.each(
      ["Local-first CMS design", "Building tenant pages", "When to use AI chat"],
      fn title ->
        upsert_entry.(blog_type, %{
          title: title,
          slug:
            title |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-"),
          payload: %{
            "title" => title,
            "excerpt" => MangoCMS.Seeds.Faker.sentence(title),
            "author" => MangoCMS.Seeds.Faker.person_name(),
            "published_at" => DateTime.utc_now(:second) |> DateTime.to_iso8601()
          }
        })
      end
    )
  end

  node = fn name, id, props, classes, children ->
    %{
      "type" => "component",
      "name" => name,
      "id" => id,
      "props" => props,
      "classes" => classes,
      "children" => children
    }
  end

  leaf = fn name, id, props, classes ->
    %{"type" => "component", "name" => name, "id" => id, "props" => props, "classes" => classes}
  end

  column = fn id, class, children ->
    node.("column", id, %{}, %{"display" => class}, children)
  end

  row = fn id, columns ->
    node.(
      "row",
      id,
      %{"gutter" => "default"},
      %{
        "display" =>
          "mx-auto grid w-full max-w-desktop grid-cols-12 gap-6 px-4 py-10 sm:px-6 lg:px-8"
      },
      columns
    )
  end

  section = fn id, class, children ->
    node.("section", id, %{}, %{"display" => class, "padding" => "py-16"}, children)
  end

  heading = fn id, text, level, classes ->
    leaf.("heading", id, %{"text" => text, "level" => Integer.to_string(level)}, %{
      "display" => classes
    })
  end

  paragraph = fn id, text, classes ->
    leaf.("paragraph", id, %{"text" => text}, %{"display" => classes})
  end

  button = fn id, text, href ->
    leaf.("button", id, %{"text" => text, "href" => href, "target" => "_self"}, %{
      "daisy_ui" => "btn btn-primary btn-lg"
    })
  end

  image = fn id, src, alt ->
    leaf.("image", id, %{"src" => src, "alt" => alt}, %{
      "display" => "aspect-video w-full rounded-xl object-cover shadow-xl"
    })
  end

  slider_row = fn id, children ->
    node.(
      "row",
      id,
      %{
        "gutter" => "slider",
        "component" => "slider_track",
        "settings" => %{
          "items_visible" => %{"desktop" => 3, "tablet" => 2, "mobile" => 1},
          "interval_ms" => 5000,
          "transition" => "slide"
        }
      },
      %{
        "display" =>
          "mx-auto flex w-full max-w-desktop snap-x snap-mandatory gap-4 overflow-x-auto scroll-smooth px-4 py-8 sm:px-6 lg:px-8"
      },
      children
    )
  end

  slider_card = fn id, children ->
    column.(
      id,
      "w-80 shrink-0 snap-start rounded-xl border border-base-300 bg-base-100 p-5 shadow-sm",
      children
    )
  end

  upsert_section = fn attrs ->
    case Pages.list_sections(tenant) |> Enum.find(&(&1.name == attrs.name)) do
      nil ->
        Pages.create_section(tenant, attrs)

      section ->
        Pages.update_section(tenant, section, attrs)
    end
    |> case do
      {:ok, section} ->
        IO.puts("Seeded section: #{section.name}")
        section

      {:error, changeset} ->
        print_changeset_errors.("Could not seed section #{attrs.name}", changeset)
        nil
    end
  end

  cta_tree =
    ContentTree.normalize_paths([
      section.("global_cta_section", "bg-primary text-primary-content", [
        row.("global_cta_row", [
          column.("global_cta_col", "col-span-12 text-center", [
            heading.(
              "global_cta_heading",
              "Ready to publish a faster tenant site?",
              2,
              "text-3xl font-bold text-primary-content"
            ),
            paragraph.(
              "global_cta_copy",
              "Start with a profile, blog, product page, resume, or AI chat experience.",
              "mx-auto mt-4 max-w-3xl text-lg text-primary-content/80"
            ),
            button.("global_cta_button", "Open admin", "/admin/dashboard")
          ])
        ])
      ])
    ])

  global_cta =
    upsert_section.(%{
      name: "Primary CTA",
      template_key: "cta.primary",
      group_label: "Marketing",
      mode: "static",
      content_tree: cta_tree,
      settings: %{
        "section_type" => "cta",
        "variant" => "primary",
        "editable_fields" => ["title", "body", "button"]
      },
      source_config: %{"kind" => "fixed"},
      filters: %{},
      loop_settings: %{"enabled" => false, "limit" => 1}
    })

  review_slider_tree =
    ContentTree.normalize_paths([
      section.("review_slider_section", "bg-base-100", [
        row.("review_slider_header_row", [
          column.("review_slider_header", "col-span-12", [
            heading.(
              "review_slider_title",
              "Loved by growing website teams",
              2,
              "text-3xl font-bold text-base-content"
            ),
            paragraph.(
              "review_slider_intro",
              "This section is dynamic-ready and loops customer review records into slider cards.",
              "mt-3 max-w-3xl text-base text-base-content/70"
            ),
            paragraph.(
              "review_slider_settings",
              "Slider: 3 desktop / 2 tablet / 1 mobile visible, 5s interval, slide transition.",
              "mt-2 text-xs font-semibold uppercase tracking-wide text-primary"
            )
          ])
        ]),
        slider_row.(
          "review_slider_cards",
          Enum.map(1..4, fn index ->
            slider_card.("review_slider_card_#{index}", [
              paragraph.(
                "review_slider_quote_#{index}",
                "MangoCMS helped us publish faster without losing tenant isolation or design control.",
                "text-base leading-7 text-base-content/80"
              ),
              heading.(
                "review_slider_name_#{index}",
                Enum.at(["Vivek Singh", "Priya Sharma", "Aarav Mehta", "Neha Kapoor"], index - 1),
                3,
                "mt-5 text-lg font-semibold text-base-content"
              ),
              paragraph.(
                "review_slider_company_#{index}",
                Enum.at(
                  ["Acme Studio", "Northstar Labs", "Saffron Cloud", "Bluepine Works"],
                  index - 1
                ),
                "mt-1 text-sm text-base-content/60"
              )
            ])
          end)
        )
      ])
    ])

  global_review_slider =
    upsert_section.(%{
      name: "Customer Review Slider",
      template_key: "slider.customer_reviews",
      group_label: "Proof",
      mode: "dynamic",
      content_tree: review_slider_tree,
      settings: %{
        "section_type" => "slider",
        "variant" => "customer_reviews",
        "items_visible" => %{"desktop" => 3, "tablet" => 2, "mobile" => 1},
        "interval_ms" => 5000,
        "transition" => "slide",
        "controls" => %{"arrows" => true, "dots" => true, "pause_on_hover" => true}
      },
      source_config: %{
        "kind" => "collection",
        "collection_slug" => "customer_reviews",
        "sort" => %{"field" => "reviewed_at", "direction" => "desc"},
        "mappings" => %{
          "title" => "payload.customer_name",
          "subtitle" => "payload.company",
          "body" => "payload.quote",
          "rating" => "payload.rating"
        }
      },
      filters: %{"rules" => [%{"field" => "rating", "op" => ">=", "value" => 4}]},
      loop_settings: %{
        "enabled" => true,
        "limit" => 6,
        "layout" => "slider",
        "item_component" => "review_card"
      }
    })

  product_slider_tree =
    ContentTree.normalize_paths([
      section.("product_slider_section", "bg-base-200", [
        row.("product_slider_header_row", [
          column.("product_slider_header", "col-span-12 md:col-span-8", [
            heading.(
              "product_slider_title",
              "Popular pressure cookers",
              2,
              "text-3xl font-bold text-base-content"
            ),
            paragraph.(
              "product_slider_intro",
              "A product slider section can loop active products or catalog collection items.",
              "mt-3 max-w-3xl text-base text-base-content/70"
            ),
            paragraph.(
              "product_slider_settings",
              "Slider: 4 desktop / 2 tablet / 1 mobile visible, 4s interval, fade transition.",
              "mt-2 text-xs font-semibold uppercase tracking-wide text-primary"
            )
          ]),
          column.("product_slider_action", "col-span-12 md:col-span-4 md:text-right", [
            button.("product_slider_button", "See all products", "/services")
          ])
        ]),
        slider_row.(
          "product_slider_cards",
          Enum.map(services, fn {_slug, name, price} ->
            slider_card.(
              "product_slider_card_#{String.replace(String.downcase(name), ~r/[^a-z0-9]+/, "_")}",
              [
                heading.(
                  "product_slider_card_title_#{String.replace(String.downcase(name), ~r/[^a-z0-9]+/, "_")}",
                  name,
                  3,
                  "text-xl font-semibold text-base-content"
                ),
                paragraph.(
                  "product_slider_card_price_#{String.replace(String.downcase(name), ~r/[^a-z0-9]+/, "_")}",
                  "From Rs. #{div(price, 100)}",
                  "mt-3 text-2xl font-bold text-primary"
                ),
                paragraph.(
                  "product_slider_card_copy_#{String.replace(String.downcase(name), ~r/[^a-z0-9]+/, "_")}",
                  MangoCMS.Seeds.Faker.sentence(name),
                  "mt-3 text-sm leading-6 text-base-content/70"
                )
              ]
            )
          end)
        )
      ])
    ])

  global_product_slider =
    upsert_section.(%{
      name: "Product Slider",
      template_key: "slider.products",
      group_label: "Commerce",
      mode: "dynamic",
      content_tree: product_slider_tree,
      settings: %{
        "section_type" => "slider",
        "variant" => "products",
        "items_visible" => %{"desktop" => 4, "tablet" => 2, "mobile" => 1},
        "interval_ms" => 4000,
        "transition" => "fade",
        "controls" => %{"arrows" => true, "dots" => true, "pause_on_hover" => true}
      },
      source_config: %{
        "kind" => "collection",
        "collection_slug" => "pressure_cookers",
        "sort" => %{"field" => "inserted_at", "direction" => "desc"},
        "mappings" => %{
          "title" => "payload.name",
          "body" => "payload.description",
          "price" => "payload.price",
          "href" => "slug"
        }
      },
      filters: %{"rules" => [%{"field" => "in_stock", "op" => "=", "value" => true}]},
      loop_settings: %{
        "enabled" => true,
        "limit" => 8,
        "layout" => "slider",
        "item_component" => "product_card"
      }
    })

  section_node = fn id, section ->
    node.(
      "section_ref",
      id,
      %{"section_id" => section.id, "name" => section.name},
      %{"display" => ""},
      section.content_tree
    )
  end

  upsert_page = fn attrs ->
    case Pages.get_page_by_slug(tenant, attrs.slug) do
      nil -> Pages.create_page(tenant, attrs)
      page -> Pages.update_page(tenant, page, attrs)
    end
    |> case do
      {:ok, page} ->
        IO.puts("Seeded page: /#{page.slug}")
        page

      {:error, changeset} ->
        print_changeset_errors.("Could not seed page #{attrs.slug}", changeset)
        nil
    end
  end

  welcome_tree =
    ContentTree.normalize_paths([
      section.("welcome_hero", "bg-base-100", [
        row.("welcome_hero_row", [
          column.("welcome_hero_copy", "col-span-12 lg:col-span-7", [
            heading.(
              "welcome_hero_title",
              "#{tenant.name} builds websites with MangoCMS",
              1,
              "text-5xl font-extrabold tracking-tight text-base-content"
            ),
            paragraph.(
              "welcome_hero_subtitle",
              "Create company profiles, blogs, product feature pages, resumes, and site-aware AI chat from one tenant-isolated admin.",
              "mt-5 max-w-3xl text-xl leading-8 text-base-content/75"
            ),
            button.("welcome_hero_button", "Explore services", "/services")
          ]),
          column.("welcome_hero_media", "col-span-12 lg:col-span-5", [
            image.("welcome_hero_image", "/images/logo.png", "#{tenant.name} logo")
          ])
        ])
      ]),
      section.("welcome_services", "bg-base-200", [
        row.("welcome_services_row", [
          column.("welcome_services_col", "col-span-12", [
            heading.(
              "welcome_services_heading",
              "Services ready for small and medium tenant sites",
              2,
              "text-3xl font-bold text-base-content"
            ),
            paragraph.(
              "welcome_services_copy",
              "Use the builder to reshape this page, then save a version before publishing changes.",
              "mt-3 text-lg text-base-content/70"
            )
          ])
        ])
      ]),
      section_node.("welcome_global_cta", global_cta)
    ])

  upsert_page.(%{
    title: "#{tenant.name} Welcome",
    slug: "welcome",
    type: "landing",
    status: "published",
    seo: %{
      "title" => "#{tenant.name} Welcome",
      "subtitle" => "Local-first tenant site builder",
      "description" => "A seeded AST-backed MangoCMS tenant page."
    },
    content_tree: welcome_tree
  })

  services_tree =
    ContentTree.normalize_paths([
      section.("services_intro", "bg-base-100", [
        row.("services_intro_row", [
          column.("services_intro_copy", "col-span-12 lg:col-span-8", [
            heading.(
              "services_intro_title",
              "Profile sites, blogs, product pages, resumes, and AI chat",
              1,
              "text-5xl font-extrabold tracking-tight text-base-content"
            ),
            paragraph.(
              "services_intro_copy_text",
              "Seeded service records also exist in Collections so dynamic sections can be added from tenant admin.",
              "mt-5 text-xl leading-8 text-base-content/75"
            )
          ]),
          column.("services_intro_action", "col-span-12 lg:col-span-4 lg:text-right", [
            button.("services_intro_button", "View customers", "/customers")
          ])
        ])
      ]),
      section_node.("services_product_slider", global_product_slider),
      section.("services_cards", "bg-base-200", [
        row.("services_cards_row", [
          column.("services_card_1", "col-span-12 md:col-span-6 lg:col-span-4", [
            heading.(
              "services_card_1_title",
              "Company Profile",
              3,
              "text-2xl font-bold text-base-content"
            ),
            paragraph.(
              "services_card_1_copy",
              "A polished public presence for teams, services, proof, and contact.",
              "mt-3 text-base text-base-content/70"
            )
          ]),
          column.("services_card_2", "col-span-12 md:col-span-6 lg:col-span-4", [
            heading.(
              "services_card_2_title",
              "Product Feature Site",
              3,
              "text-2xl font-bold text-base-content"
            ),
            paragraph.(
              "services_card_2_copy",
              "Focused pages for launches, feature tours, and conversion CTAs.",
              "mt-3 text-base text-base-content/70"
            )
          ]),
          column.("services_card_3", "col-span-12 md:col-span-6 lg:col-span-4", [
            heading.(
              "services_card_3_title",
              "AI Chat",
              3,
              "text-2xl font-bold text-base-content"
            ),
            paragraph.(
              "services_card_3_copy",
              "A future-ready assistant that answers questions from website content.",
              "mt-3 text-base text-base-content/70"
            )
          ])
        ])
      ]),
      section_node.("services_global_cta", global_cta)
    ])

  upsert_page.(%{
    title: "Services",
    slug: "services",
    type: "page",
    status: "published",
    seo: %{
      "title" => "Services",
      "subtitle" => "What #{tenant.name} offers",
      "description" => "Seeded MangoCMS services page."
    },
    content_tree: services_tree
  })

  customers_tree =
    ContentTree.normalize_paths([
      section.("customers_intro", "bg-base-100", [
        row.("customers_intro_row", [
          column.("customers_intro_col", "col-span-12", [
            heading.(
              "customers_intro_title",
              "Customer stories and positive reviews",
              1,
              "text-5xl font-extrabold tracking-tight text-base-content"
            ),
            paragraph.(
              "customers_intro_copy",
              "The tenant database also includes seeded Customer Review entries for dynamic card sections.",
              "mt-5 max-w-3xl text-xl leading-8 text-base-content/75"
            )
          ])
        ])
      ]),
      section_node.("customers_review_slider", global_review_slider),
      section.("customers_quotes", "bg-base-200", [
        row.("customers_quotes_row", [
          column.("customers_quote_1", "col-span-12 md:col-span-4", [
            paragraph.(
              "customers_quote_1_copy",
              "\"We launched a clean company website without pulling engineering away.\"",
              "text-lg italic text-base-content/80"
            ),
            heading.(
              "customers_quote_1_name",
              "Aditi Sharma",
              3,
              "mt-4 text-lg font-bold text-base-content"
            )
          ]),
          column.("customers_quote_2", "col-span-12 md:col-span-4", [
            paragraph.(
              "customers_quote_2_copy",
              "\"The local-first tenant setup is fast and easy to operate.\"",
              "text-lg italic text-base-content/80"
            ),
            heading.(
              "customers_quote_2_name",
              "Rahul Mehta",
              3,
              "mt-4 text-lg font-bold text-base-content"
            )
          ]),
          column.("customers_quote_3", "col-span-12 md:col-span-4", [
            paragraph.(
              "customers_quote_3_copy",
              "\"Our product launch page finally feels simple to update.\"",
              "text-lg italic text-base-content/80"
            ),
            heading.(
              "customers_quote_3_name",
              "Priya Nair",
              3,
              "mt-4 text-lg font-bold text-base-content"
            )
          ])
        ])
      ]),
      section_node.("customers_global_cta", global_cta)
    ])

  upsert_page.(%{
    title: "Customer Stories",
    slug: "customers",
    type: "page",
    status: "published",
    seo: %{
      "title" => "Customer Stories",
      "subtitle" => "Reviews",
      "description" => "Seeded customer proof page."
    },
    content_tree: customers_tree
  })

  upsert_page.(%{
    title: "Resume",
    slug: "resume",
    type: "page",
    status: "published",
    seo: %{
      "title" => "Resume",
      "subtitle" => "Personal site",
      "description" => "Seeded resume page."
    },
    content_tree:
      ContentTree.normalize_paths([
        section.("resume_intro", "bg-base-100", [
          row.("resume_intro_row", [
            column.("resume_intro_col", "col-span-12 lg:col-span-8", [
              heading.(
                "resume_intro_title",
                "A resume website managed in MangoCMS",
                1,
                "text-5xl font-extrabold tracking-tight text-base-content"
              ),
              paragraph.(
                "resume_intro_copy",
                "Show experience, projects, references, and contact links with the same builder used for business pages.",
                "mt-5 text-xl leading-8 text-base-content/75"
              ),
              button.("resume_intro_button", "Contact me", "mailto:hello@#{tenant.domain}")
            ])
          ])
        ]),
        section_node.("resume_global_cta", global_cta)
      ])
  })
end

IO.puts("Seed complete.")
