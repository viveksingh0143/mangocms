import Ecto.Query

require IEx
alias MangoCMS.Platform
alias MangoCMS.Platform.Accounts
alias MangoCMS.Platform.Accounts.User, as: PlatformUser
alias MangoCMS.Repo
alias MangoCMS.Tenant.Accounts, as: TenantAccounts
alias MangoCMS.Tenant.Catalog
alias MangoCMS.Tenant.Catalog.Product
alias MangoCMS.Tenant.ContentEngine
alias MangoCMS.Tenant.Migrator, as: TenantMigrator
alias MangoCMS.Tenant.RepoManager, as: TenantRepoManager
alias MangoCMS.Tenant.Settings, as: TenantSettings

dbg("Starting seeds...")

default_seed_password = if Mix.env() == :prod, do: nil, else: "P@ssw0rd123"

seed_password = fn env_name ->
  System.get_env(env_name) || System.get_env("SEED_PASSWORD") || default_seed_password
end

valid_password? = fn value -> is_binary(value) and String.length(value) >= 8 end

days_ago_iso = fn days ->
  DateTime.utc_now(:second)
  |> DateTime.add(-days * 86_400, :second)
  |> DateTime.to_iso8601()
end

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

seed_platform_user = fn role, email, password, password_env_name, full_name ->
  identity_key = PlatformUser.identity_key("platform", nil, email)
  attrs = %{email: email, full_name: full_name, role: role, timezone: "UTC", locale: "en"}

  case Repo.get_by(PlatformUser, identity_key: identity_key) do
    %PlatformUser{} = user ->
      case Accounts.update_user(user, attrs) do
        {:ok, user} ->
          confirm_platform_user.(user)
          IO.puts("Updated platform #{role}: #{email}")

        {:error, changeset} ->
          print_changeset_errors.("Could not update platform #{role} #{email}", changeset)
      end

    nil ->
      if valid_password?.(password) do
        case Accounts.create_user(Map.put(attrs, :password, password)) do
          {:ok, user} ->
            confirm_platform_user.(user)
            IO.puts("Created platform #{role}: #{email}")

          {:error, changeset} ->
            print_changeset_errors.("Could not create platform #{role} #{email}", changeset)
        end
      else
        IO.puts("""
        Skipping platform #{role}: #{email}
        Set #{password_env_name} or SEED_PASSWORD to at least 8 characters.
        """)
      end
  end
end

seed_plan = fn attrs ->
  name = attrs.name

  case Platform.get_plan_by_name(name) do
    nil ->
      case Platform.create_plan(attrs) do
        {:ok, plan} ->
          IO.puts("Created plan: #{plan.display_name}")
          plan

        {:error, changeset} ->
          print_changeset_errors.("Could not create plan #{name}", changeset)
          nil
      end

    plan ->
      case Platform.update_plan(plan, attrs) do
        {:ok, plan} ->
          IO.puts("Updated plan: #{plan.display_name}")
          plan

        {:error, changeset} ->
          print_changeset_errors.("Could not update plan #{name}", changeset)
          plan
      end
  end
end

owner_email = System.get_env("PLATFORM_OWNER_EMAIL", "owner@mangocms.local")
owner_password = seed_password.("PLATFORM_OWNER_PASSWORD")
owner_name = System.get_env("PLATFORM_OWNER_NAME", "Platform Owner")

admin_email = System.get_env("PLATFORM_ADMIN_EMAIL", "admin@mangocms.local")
admin_password = seed_password.("PLATFORM_ADMIN_PASSWORD")
admin_name = System.get_env("PLATFORM_ADMIN_NAME", "Platform Admin")

customer_email = System.get_env("PLATFORM_CUSTOMER_EMAIL", "customer@mangocms.local")
customer_password = seed_password.("PLATFORM_CUSTOMER_PASSWORD")
customer_name = System.get_env("PLATFORM_CUSTOMER_NAME", "Demo Customer")

seed_platform_user.("owner", owner_email, owner_password, "PLATFORM_OWNER_PASSWORD", owner_name)
seed_platform_user.("admin", admin_email, admin_password, "PLATFORM_ADMIN_PASSWORD", admin_name)

seed_platform_user.(
  "customer",
  customer_email,
  customer_password,
  "PLATFORM_CUSTOMER_PASSWORD",
  customer_name
)

starter_plan =
  seed_plan.(%{
    name: "starter",
    display_name: "Starter",
    description: "Launch a fast company profile, resume, or blog with the essentials.",
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
      "custom_domain" => false,
      "product_features" => true,
      "resume" => true
    },
    custom_domain_support: false,
    api_access: false,
    priority_support: false,
    white_label: false,
    sort_order: 10
  })

seed_plan.(%{
  name: "pro",
  display_name: "Pro",
  description: "Grow a tenant site with custom domains, more users, and richer content.",
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
})

seed_plan.(%{
  name: "enterprise",
  display_name: "Enterprise",
  description: "Higher limits, priority support, and white-label site operations.",
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
})

tenant_owner_email = System.get_env("TENANT_OWNER_EMAIL", "owner@acme.localhost")
tenant_owner_password = seed_password.("TENANT_OWNER_PASSWORD")
tenant_owner_name = System.get_env("TENANT_OWNER_NAME", "Acme Owner")

tenant_base_attrs = %{
  name: System.get_env("TENANT_NAME", "Acme Studio"),
  domain: System.get_env("TENANT_DOMAIN", "acme.localhost"),
  subdomain: System.get_env("TENANT_SUBDOMAIN", "acme"),
  slug: System.get_env("TENANT_SLUG", "acme"),
  status: "active",
  active: true,
  plan_id: starter_plan && starter_plan.id
}

tenant =
  cond do
    is_nil(starter_plan) ->
      IO.puts("Skipping demo tenant because the starter plan could not be seeded.")
      nil

    tenant = Platform.get_tenant_by_subdomain_with_plan(tenant_base_attrs.subdomain) ->
      case Platform.update_tenant(tenant, tenant_base_attrs) do
        {:ok, tenant} ->
          IO.puts("Updated tenant: #{tenant.name}")
          Platform.get_tenant_with_plan!(tenant.id)

        {:error, changeset} ->
          print_changeset_errors.(
            "Could not update tenant #{tenant_base_attrs.subdomain}",
            changeset
          )

          tenant
      end

    true ->
      dbg(tenant_owner_password)

      create_attrs =
        if valid_password?.(tenant_owner_password) do
          dbg("Valid Password")

          Map.merge(tenant_base_attrs, %{
            owner_email: tenant_owner_email,
            owner_password: tenant_owner_password,
            owner_full_name: tenant_owner_name
          })
        else
          dbg("Not Valid Password")
          tenant_base_attrs
        end

      case Platform.create_tenant(create_attrs) do
        {:ok, tenant} ->
          IO.puts("Created tenant: #{tenant.name}")
          Platform.get_tenant_with_plan!(tenant.id)

        {:error, changeset} ->
          print_changeset_errors.(
            "Could not create tenant #{tenant_base_attrs.subdomain}",
            changeset
          )

          nil
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

  tenant
  |> TenantSettings.get_or_create_site_settings!()
  |> then(fn settings ->
    attrs = %{
      site_name: tenant.name,
      tagline:
        "Launch company sites, blogs, resumes, and product pages from one local-first CMS.",
      support_email: "support@#{tenant.domain}",
      locale: "en",
      timezone: "Asia/Kolkata"
    }

    case TenantSettings.update_site_settings(tenant, settings, attrs) do
      {:ok, _settings} ->
        IO.puts("Updated tenant settings: #{tenant.name}")

      {:error, changeset} ->
        print_changeset_errors.("Could not update tenant settings #{tenant.name}", changeset)
    end
  end)

  dbg(tenant_owner_password)

  if valid_password?.(tenant_owner_password) do
    case TenantAccounts.get_user_by_email(tenant, tenant_owner_email) do
      nil ->
        case TenantAccounts.register_owner_user(tenant, %{
               email: tenant_owner_email,
               password: tenant_owner_password,
               full_name: tenant_owner_name,
               locale: "en",
               timezone: "Asia/Kolkata"
             }) do
          {:ok, user} ->
            confirm_tenant_user.(user)

            IO.puts(
              "Created tenant owner: #{tenant_owner_email}, with password: #{tenant_owner_password}"
            )

          {:error, changeset} ->
            print_changeset_errors.(
              "Could not create tenant owner #{tenant_owner_email}",
              changeset
            )
        end

      user ->
        case TenantAccounts.update_user(tenant, user, %{
               email: tenant_owner_email,
               full_name: tenant_owner_name,
               role: "owner",
               locale: "en",
               timezone: "Asia/Kolkata"
             }) do
          {:ok, user} ->
            confirm_tenant_user.(user)
            IO.puts("Updated tenant owner: #{tenant_owner_email}")

          {:error, changeset} ->
            print_changeset_errors.(
              "Could not update tenant owner #{tenant_owner_email}",
              changeset
            )
        end
    end
  else
    IO.puts("""
    Skipping tenant owner for #{tenant.name}.
    Set TENANT_OWNER_PASSWORD or SEED_PASSWORD to at least 8 characters.
    """)
  end

  seed_product = fn attrs ->
    product =
      TenantRepoManager.with_repo(tenant, fn repo ->
        repo.one(from product in Product, where: product.slug == ^attrs.slug, limit: 1)
      end)

    case product do
      nil ->
        case Catalog.create_product(tenant, attrs) do
          {:ok, product} ->
            IO.puts("Created tenant product: #{product.name}")
            product

          {:error, changeset} ->
            print_changeset_errors.("Could not create tenant product #{attrs.name}", changeset)
            nil
        end

      product ->
        case Catalog.update_product(tenant, product, attrs) do
          {:ok, product} ->
            IO.puts("Updated tenant product: #{product.name}")
            product

          {:error, changeset} ->
            print_changeset_errors.("Could not update tenant product #{attrs.name}", changeset)
            product
        end
    end
  end

  seed_product.(%{
    name: "Company Profile Website",
    slug: "company-profile-website",
    sku: "ACME-WEB-001",
    description: "A polished profile site for teams that need a fast public presence.",
    status: "active",
    price: 149_900,
    currency: "INR",
    stock_quantity: 100,
    active: true
  })

  seed_product.(%{
    name: "AI Chat Add-on",
    slug: "ai-chat-add-on",
    sku: "ACME-AI-001",
    description: "A site-aware assistant that answers visitor questions from tenant content.",
    status: "active",
    price: 49_900,
    currency: "INR",
    stock_quantity: 100,
    active: true
  })

  seed_product.(%{
    name: "Product Feature Microsite",
    slug: "product-feature-microsite",
    sku: "ACME-PROD-001",
    description: "Focused landing pages for product launches, feature tours, and proof points.",
    status: "active",
    price: 199_900,
    currency: "INR",
    stock_quantity: 100,
    active: true
  })

  seed_content_type = fn attrs, fields ->
    content_type =
      case ContentEngine.get_content_type_by_slug(tenant, attrs.slug) do
        nil ->
          case ContentEngine.create_content_type(tenant, attrs) do
            {:ok, content_type} ->
              IO.puts("Created content type: #{content_type.name}")
              content_type

            {:error, changeset} ->
              print_changeset_errors.("Could not create content type #{attrs.slug}", changeset)
              nil
          end

        content_type ->
          case ContentEngine.update_content_type(tenant, content_type, attrs) do
            {:ok, content_type} ->
              IO.puts("Updated content type: #{content_type.name}")
              content_type

            {:error, changeset} ->
              print_changeset_errors.("Could not update content type #{attrs.slug}", changeset)
              content_type
          end
      end

    if content_type do
      existing_fields =
        tenant
        |> ContentEngine.list_content_type_fields(content_type)
        |> Map.new(&{&1.field_key, &1})

      Enum.each(fields, fn field_attrs ->
        case Map.get(existing_fields, field_attrs.field_key) do
          nil ->
            case ContentEngine.create_content_type_field(tenant, content_type, field_attrs) do
              {:ok, field} ->
                IO.puts("Created content field: #{content_type.slug}.#{field.field_key}")

              {:error, changeset} ->
                print_changeset_errors.(
                  "Could not create content field #{content_type.slug}.#{field_attrs.field_key}",
                  changeset
                )
            end

          field ->
            case ContentEngine.update_content_type_field(tenant, field, field_attrs) do
              {:ok, field} ->
                IO.puts("Updated content field: #{content_type.slug}.#{field.field_key}")

              {:error, changeset} ->
                print_changeset_errors.(
                  "Could not update content field #{content_type.slug}.#{field_attrs.field_key}",
                  changeset
                )
            end
        end
      end)
    end

    content_type
  end

  seed_entry = fn content_type, attrs ->
    case ContentEngine.get_entry_by_slug(tenant, content_type, attrs.slug) do
      nil ->
        case ContentEngine.create_entry(tenant, content_type, attrs) do
          {:ok, entry} ->
            {:ok, entry} = ContentEngine.publish_entry(tenant, entry)
            IO.puts("Created content entry: #{entry.title || entry.slug}")
            entry

          {:error, changeset} ->
            print_changeset_errors.("Could not create content entry #{attrs.slug}", changeset)
            nil
        end

      entry ->
        case ContentEngine.update_entry(tenant, entry, attrs) do
          {:ok, entry} ->
            {:ok, entry} = ContentEngine.publish_entry(tenant, entry)
            IO.puts("Updated content entry: #{entry.title || entry.slug}")
            entry

          {:error, changeset} ->
            print_changeset_errors.("Could not update content entry #{attrs.slug}", changeset)
            entry
        end
    end
  end

  product_type =
    seed_content_type.(
      %{
        name: "Products",
        slug: "products",
        description: "Dynamic product-style entries for cards, pricing, and feature grids.",
        status: "active",
        settings: %{"icon" => "shopping-bag"}
      },
      [
        %{
          label: "Name",
          field_key: "name",
          field_type: "string",
          required: true,
          indexed: true,
          filterable: false,
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
          label: "Rating",
          field_key: "rating",
          field_type: "number",
          required: false,
          indexed: true,
          filterable: true,
          sortable: true,
          position: 30
        },
        %{
          label: "On Sale",
          field_key: "on_sale",
          field_type: "boolean",
          required: false,
          indexed: true,
          filterable: true,
          sortable: false,
          position: 40
        },
        %{
          label: "Image URL",
          field_key: "image_url",
          field_type: "image",
          required: false,
          indexed: false,
          filterable: false,
          sortable: false,
          position: 50
        },
        %{
          label: "Description",
          field_key: "description",
          field_type: "text",
          required: false,
          indexed: true,
          filterable: false,
          sortable: false,
          position: 60
        }
      ]
    )

  if product_type do
    seed_entry.(product_type, %{
      title: "Company Profile Website",
      slug: "company-profile-website",
      payload: %{
        "name" => "Company Profile Website",
        "price" => 149_900,
        "rating" => 4.9,
        "on_sale" => true,
        "image_url" => "/images/demo/company-profile.jpg",
        "description" => "A polished company website with pages, testimonials, and contact flows."
      }
    })

    seed_entry.(product_type, %{
      title: "AI Chat Add-on",
      slug: "ai-chat-add-on",
      payload: %{
        "name" => "AI Chat Add-on",
        "price" => 49_900,
        "rating" => 4.8,
        "on_sale" => false,
        "image_url" => "/images/demo/ai-chat.jpg",
        "description" => "A tenant-aware assistant that answers questions from website content."
      }
    })
  end

  review_type =
    seed_content_type.(
      %{
        name: "Customer Reviews",
        slug: "customer_reviews",
        description: "Reusable customer proof for review grids and testimonial sections.",
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
          filterable: false,
          sortable: true,
          position: 10
        },
        %{
          label: "Rating",
          field_key: "rating",
          field_type: "number",
          required: true,
          indexed: true,
          filterable: true,
          sortable: true,
          position: 20
        },
        %{
          label: "Quote",
          field_key: "quote",
          field_type: "text",
          required: true,
          indexed: true,
          filterable: false,
          sortable: false,
          position: 30
        },
        %{
          label: "Reviewed At",
          field_key: "reviewed_at",
          field_type: "datetime",
          required: false,
          indexed: true,
          filterable: true,
          sortable: true,
          position: 40
        }
      ]
    )

  if review_type do
    seed_entry.(review_type, %{
      title: "Aditi Sharma Review",
      slug: "aditi-sharma-review",
      payload: %{
        "customer_name" => "Aditi Sharma",
        "rating" => 5,
        "quote" =>
          "We launched a fast, clean company website without pulling our engineering team away.",
        "reviewed_at" => days_ago_iso.(21)
      }
    })

    seed_entry.(review_type, %{
      title: "Rahul Mehta Review",
      slug: "rahul-mehta-review",
      payload: %{
        "customer_name" => "Rahul Mehta",
        "rating" => 5,
        "quote" =>
          "The local-first tenant setup feels simple, fast, and reliable for small business sites.",
        "reviewed_at" => days_ago_iso.(7)
      }
    })
  end

  team_type =
    seed_content_type.(
      %{
        name: "Team Members",
        slug: "team_members",
        description: "People records for team grids, resume pages, and profile sections.",
        status: "active",
        settings: %{"icon" => "users"}
      },
      [
        %{
          label: "Full Name",
          field_key: "full_name",
          field_type: "string",
          required: true,
          indexed: true,
          filterable: false,
          sortable: true,
          position: 10
        },
        %{
          label: "Role",
          field_key: "role",
          field_type: "string",
          required: true,
          indexed: true,
          filterable: true,
          sortable: true,
          position: 20
        },
        %{
          label: "Biography",
          field_key: "biography",
          field_type: "text",
          required: false,
          indexed: true,
          filterable: false,
          sortable: false,
          position: 30
        },
        %{
          label: "Avatar URL",
          field_key: "avatar_url",
          field_type: "image",
          required: false,
          indexed: false,
          filterable: false,
          sortable: false,
          position: 40
        }
      ]
    )

  if team_type do
    seed_entry.(team_type, %{
      title: "Maya Iyer",
      slug: "maya-iyer",
      payload: %{
        "full_name" => "Maya Iyer",
        "role" => "Founder",
        "biography" => "Builds practical websites and content systems for growing teams.",
        "avatar_url" => "/images/demo/maya-iyer.jpg"
      }
    })

    seed_entry.(team_type, %{
      title: "Arjun Rao",
      slug: "arjun-rao",
      payload: %{
        "full_name" => "Arjun Rao",
        "role" => "Product Lead",
        "biography" => "Turns product stories into clear pages, cards, and launch content.",
        "avatar_url" => "/images/demo/arjun-rao.jpg"
      }
    })
  end
end
