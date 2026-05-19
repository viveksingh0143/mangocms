defmodule MangoCMSWeb.Builder.Manifest do
  @moduledoc """
  Behaviour and normalization helpers for Elixir-native builder manifests.
  """

  @type slot :: %{
          required(:id) => String.t(),
          required(:label) => String.t(),
          required(:accepts) => [String.t()],
          optional(:max_children) => pos_integer() | nil,
          optional(:required) => boolean()
        }

  @type variant :: %{
          required(:id) => String.t(),
          required(:label) => String.t(),
          optional(:description) => String.t(),
          optional(:default_props) => map(),
          optional(:default_classes) => map(),
          optional(:fields) => [atom()],
          optional(:slots) => [String.t()]
        }

  @type t :: %{
          required(:name) => String.t(),
          required(:label) => String.t(),
          required(:group) => String.t(),
          required(:icon) => String.t(),
          required(:renderer) => {module(), atom()},
          required(:default_variant) => String.t(),
          required(:variants) => [variant()],
          required(:default_props) => map(),
          required(:default_classes) => map(),
          required(:fields) => %{atom() => MangoCMSWeb.Builder.Field.t()},
          required(:slots) => [slot()],
          required(:accepted_children) => [String.t()],
          required(:alpine) => map(),
          optional(:examples) => [map()]
        }

  @callback manifest() :: t()

  @doc "Normalizes optional manifest keys so registry callers can rely on shape."
  @spec normalize(t()) :: t()
  def normalize(manifest) when is_map(manifest) do
    manifest
    |> Map.put_new(:default_props, %{})
    |> Map.put_new(:default_classes, %{})
    |> Map.put_new(:variants, [])
    |> Map.put_new(:fields, %{})
    |> Map.put_new(:slots, [])
    |> Map.put_new(:accepted_children, [])
    |> Map.put_new(:alpine, %{})
    |> Map.put_new(:examples, [])
  end
end
