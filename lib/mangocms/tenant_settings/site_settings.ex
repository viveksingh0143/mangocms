defmodule MangoCMS.TenantSettings.SiteSettings do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @timestamps_opts [type: :utc_datetime]

  @fixed_id "site"
  @fields ~w(site_name tagline logo_url dark_logo_url support_email locale timezone)a

  @type t :: %__MODULE__{}

  schema "site_settings" do
    field :site_name, :string
    field :tagline, :string
    field :logo_url, :string
    field :dark_logo_url, :string
    field :support_email, :string
    field :locale, :string, default: "en"
    field :timezone, :string, default: "UTC"

    timestamps()
  end

  def fixed_id, do: @fixed_id

  def default_attrs(site_name) do
    %{
      "id" => @fixed_id,
      "site_name" => site_name,
      "locale" => "en",
      "timezone" => "UTC"
    }
  end

  def changeset(settings, attrs) do
    settings
    |> ensure_id()
    |> cast(attrs, @fields)
    |> validate_required([:site_name, :locale, :timezone])
    |> validate_length(:site_name, min: 2, max: 120)
    |> validate_length(:tagline, max: 180)
    |> validate_length(:logo_url, max: 500)
    |> validate_length(:dark_logo_url, max: 500)
    |> validate_length(:support_email, max: 160)
    |> validate_length(:locale, max: 20)
    |> validate_length(:timezone, max: 80)
    |> validate_format(:support_email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
  end

  defp ensure_id(%__MODULE__{id: nil} = settings), do: %{settings | id: @fixed_id}
  defp ensure_id(settings), do: settings
end
