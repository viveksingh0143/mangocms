defmodule MangoCMSWeb.Tenant.Admin.ContentEntryLive.FormComponent do
  use MangoCMSWeb, :live_component

  alias MangoCMS.Tenant.ContentEngine
  alias MangoCMS.Tenant.ContentEngine.{ContentEntry, ContentTypeField}
  alias MangoCMS.Uploads
  alias MangoCMSWeb.CoreComponents

  @status_options ContentEntry.status_options()

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :media_uploads, Map.get(assigns, :uploads, %{}))

    ~H"""
    <section class="rounded-lg border border-base-300 bg-base-100 p-6 text-base-content shadow-sm transition-colors">
      <.header>
        {@title}
        <:subtitle>{@content_type.name} entries are validated against this tenant schema.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="content-entry-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid gap-5 md:grid-cols-3">
          <.input field={@form[:title]} type="text" label="Title" placeholder="Budget Website" />
          <.input field={@form[:slug]} type="text" label="Slug" placeholder="budget-website" />
          <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
        </div>

        <div class="mt-4 rounded-lg border border-base-300 bg-base-200 p-4">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h3 class="font-semibold text-base-content">Payload</h3>
              <p class="text-sm text-base-content/60">
                Inputs are generated from the fields on {@content_type.name}.
              </p>
            </div>
            <span class="rounded-full bg-base-100 px-2.5 py-1 text-xs font-semibold text-base-content/70">
              {length(@fields)} fields
            </span>
          </div>

          <div
            :if={@payload_errors != []}
            id="content-entry-payload-errors"
            class="mt-4 rounded-lg border border-error/20 bg-error/10 p-3 text-sm text-error"
          >
            <p :for={error <- @payload_errors}>{error}</p>
          </div>

          <div class="mt-5 grid gap-5 md:grid-cols-2">
            <.payload_input
              :for={field <- @fields}
              form={@form}
              field_def={field}
              uploads={@media_uploads}
            />
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <.button navigate={@patch} class="btn btn-ghost">Cancel</.button>
          <.button id="save-content-entry-button" variant="primary" phx-disable-with="Saving...">
            Save entry
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  @impl true
  def update(%{entry: entry} = assigns, socket) do
    changeset = ContentEngine.change_entry(entry, assigns.fields)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:status_options, @status_options)
     |> assign_form(changeset)
     |> allow_media_uploads(assigns.fields)}
  end

  @impl true
  def handle_event("validate", %{"content_entry" => entry_params}, socket) do
    params = normalize_entry_params(entry_params, socket.assigns.fields, socket.assigns.entry)

    changeset =
      socket.assigns.entry
      |> ContentEngine.change_entry(socket.assigns.fields, params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"content_entry" => entry_params}, socket) do
    params =
      entry_params
      |> put_uploaded_media(socket)
      |> normalize_entry_params(socket.assigns.fields, socket.assigns.entry)

    save_entry(socket, socket.assigns.action, params)
  end

  defp save_entry(socket, :new, entry_params) do
    case ContentEngine.create_entry(
           socket.assigns.tenant,
           socket.assigns.content_type,
           entry_params
         ) do
      {:ok, entry} ->
        notify_parent({:saved, entry})

        {:noreply,
         socket
         |> put_flash(:info, "Content entry created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_entry(socket, :edit, entry_params) do
    case ContentEngine.update_entry(socket.assigns.tenant, socket.assigns.entry, entry_params) do
      {:ok, entry} ->
        notify_parent({:saved, entry})

        {:noreply,
         socket
         |> put_flash(:info, "Content entry updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp payload_input(assigns) do
    field = assigns.field_def

    assigns =
      assigns
      |> assign(:field_key, field.field_key)
      |> assign(:input_id, "content_entry_payload_#{field.field_key}")
      |> assign(:input_name, "content_entry[payload][#{field.field_key}]")
      |> assign(:input_type, payload_input_type(field))
      |> assign(:input_value, payload_value(assigns.form, field))
      |> assign(:input_label, payload_label(field))
      |> assign(:input_options, select_options(field))
      |> assign(:media_field?, media_field?(field))
      |> assign(:upload_config, Map.get(assigns.uploads || %{}, media_upload_name(field)))

    ~H"""
    <div class={[@input_type == "textarea" && "md:col-span-2"]}>
      <.input
        :if={@input_type == "select"}
        id={@input_id}
        name={@input_name}
        type="select"
        label={@input_label}
        value={@input_value}
        options={@input_options}
        prompt="Choose an option"
      />

      <.input
        :if={@input_type == "textarea"}
        id={@input_id}
        name={@input_name}
        type="textarea"
        label={@input_label}
        value={@input_value}
        rows="4"
      />

      <.input
        :if={@input_type == "checkbox"}
        id={@input_id}
        name={@input_name}
        type="checkbox"
        label={@input_label}
        value={@input_value}
      />

      <.input
        :if={@input_type not in ["select", "textarea", "checkbox"] and !@media_field?}
        id={@input_id}
        name={@input_name}
        type={@input_type}
        label={@input_label}
        value={@input_value}
        step={if(@input_type == "number", do: "any", else: nil)}
      />

      <div :if={@media_field?} class="grid gap-2">
        <.input
          id={@input_id}
          name={@input_name}
          type={if(@field_def.field_type == "gallery", do: "textarea", else: "text")}
          label={@input_label}
          value={@input_value}
          rows={if(@field_def.field_type == "gallery", do: "4", else: nil)}
          placeholder="/uploads/tenants/..."
        />
        <div
          :if={@upload_config}
          id={"#{@input_id}_upload"}
          class="rounded-lg border border-dashed border-base-300 bg-base-100 p-3"
        >
          <div class="relative">
            <.live_file_input
              upload={@upload_config}
              class="absolute inset-0 z-10 h-full w-full cursor-pointer opacity-0"
            />
            <span class="btn btn-outline btn-sm w-full pointer-events-none">
              Upload {media_upload_label(@field_def)}
            </span>
          </div>
          <div class="mt-2 grid gap-1">
            <p :for={entry <- @upload_config.entries} class="text-xs text-base-content/60">
              {entry.client_name} · {entry.progress}%
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp allow_media_uploads(socket, fields) do
    Enum.reduce(media_fields(fields), socket, fn field, socket ->
      upload_name = media_upload_name(field)

      if Map.has_key?(socket.assigns[:uploads] || %{}, upload_name) do
        socket
      else
        allow_upload(socket, upload_name,
          accept: media_accept(field),
          max_entries: media_max_entries(field),
          max_file_size: media_max_file_size(field),
          auto_upload: true
        )
      end
    end)
  end

  defp put_uploaded_media(params, socket) do
    Enum.reduce(media_fields(socket.assigns.fields), params, fn field, params ->
      upload_name = media_upload_name(field)

      consume_uploaded_entries(socket, upload_name, fn meta, entry ->
        {:ok,
         Uploads.store_live_upload!(entry, meta, {:tenant, socket.assigns.tenant},
           type: [
             "content",
             socket.assigns.content_type.id,
             field.field_key,
             media_directory(field)
           ]
         )}
      end)
      |> case do
        urls when urls != [] ->
          Map.update(params, "payload", media_payload_default(field, urls), fn payload ->
            put_media_payload_value(safe_map(payload), field, urls)
          end)

        [] ->
          params
      end
    end)
  end

  defp media_payload_default(%ContentTypeField{field_type: "gallery"} = field, urls) do
    %{field.field_key => urls}
  end

  defp media_payload_default(%ContentTypeField{} = field, [url | _rest]) do
    %{field.field_key => url}
  end

  defp put_media_payload_value(payload, %ContentTypeField{field_type: "gallery"} = field, urls) do
    existing =
      payload
      |> Map.get(field.field_key)
      |> then(&coerce_payload_value(field, &1))

    Map.put(payload, field.field_key, Enum.uniq(existing ++ urls))
  end

  defp put_media_payload_value(payload, %ContentTypeField{} = field, [url | _rest]) do
    Map.put(payload, field.field_key, url)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(:form, to_form(changeset))
    |> assign(:payload_errors, payload_errors(changeset))
  end

  defp payload_errors(%Ecto.Changeset{} = changeset) do
    changeset.errors
    |> Keyword.get_values(:payload)
    |> Enum.map(&CoreComponents.translate_error/1)
  end

  defp normalize_entry_params(params, fields, %ContentEntry{} = entry) do
    payload = Map.get(params, "payload", %{})

    normalized_payload =
      fields
      |> Enum.map(fn field ->
        {field.field_key, coerce_payload_value(field, Map.get(payload, field.field_key))}
      end)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    params
    |> Map.put("payload", normalized_payload)
    |> maybe_put_published_at(entry)
  end

  defp maybe_put_published_at(%{"status" => "published"} = params, %ContentEntry{
         published_at: nil
       }) do
    Map.put(params, "published_at", DateTime.utc_now(:second))
  end

  defp maybe_put_published_at(params, _entry), do: params

  defp coerce_payload_value(_field, value) when value in [nil, ""], do: nil

  defp coerce_payload_value(%ContentTypeField{field_type: "number"}, value)
       when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _other -> value
    end
  end

  defp coerce_payload_value(%ContentTypeField{field_type: "boolean"}, value) do
    value in [true, "true", "1", 1]
  end

  defp coerce_payload_value(%ContentTypeField{field_type: "json"}, value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, decoded} -> decoded
      {:error, _reason} -> value
    end
  end

  defp coerce_payload_value(%ContentTypeField{field_type: "gallery"}, value)
       when is_binary(value) do
    value
    |> String.split(~r/[\n,]/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp coerce_payload_value(%ContentTypeField{field_type: "gallery"}, value)
       when is_list(value) do
    value
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp coerce_payload_value(_field, value), do: value

  defp payload_input_type(%ContentTypeField{field_type: "text"}), do: "textarea"
  defp payload_input_type(%ContentTypeField{field_type: "json"}), do: "textarea"
  defp payload_input_type(%ContentTypeField{field_type: "number"}), do: "number"
  defp payload_input_type(%ContentTypeField{field_type: "boolean"}), do: "checkbox"
  defp payload_input_type(%ContentTypeField{field_type: "datetime"}), do: "datetime-local"
  defp payload_input_type(%ContentTypeField{field_type: "url"}), do: "url"
  defp payload_input_type(%ContentTypeField{field_type: "image"}), do: "text"
  defp payload_input_type(%ContentTypeField{field_type: "video"}), do: "text"
  defp payload_input_type(%ContentTypeField{field_type: "gallery"}), do: "textarea"
  defp payload_input_type(%ContentTypeField{field_type: "select"}), do: "select"
  defp payload_input_type(_field), do: "text"

  defp payload_label(%ContentTypeField{} = field) do
    if field.required, do: "#{field.label} *", else: field.label
  end

  defp payload_value(form, %ContentTypeField{} = field) do
    payload =
      case form[:payload].value do
        value when is_map(value) -> value
        _other -> %{}
      end

    payload
    |> Map.get(field.field_key)
    |> format_payload_value(field)
  end

  defp format_payload_value(value, _field) when value in [nil, ""], do: nil

  defp format_payload_value(value, %ContentTypeField{field_type: "datetime"}) do
    value
    |> datetime_to_string()
    |> String.slice(0, 16)
  end

  defp format_payload_value(value, %ContentTypeField{field_type: "json"}) when is_binary(value),
    do: value

  defp format_payload_value(value, %ContentTypeField{field_type: "json"}) do
    Jason.encode!(value)
  end

  defp format_payload_value(value, %ContentTypeField{field_type: "gallery"})
       when is_list(value) do
    Enum.join(value, "\n")
  end

  defp format_payload_value(value, _field), do: value

  defp datetime_to_string(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp datetime_to_string(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp datetime_to_string(%Date{} = value), do: Date.to_iso8601(value)
  defp datetime_to_string(value) when is_binary(value), do: value
  defp datetime_to_string(value), do: to_string(value)

  defp select_options(%ContentTypeField{settings: settings}) when is_map(settings) do
    settings
    |> Map.get("options", [])
    |> case do
      options when is_list(options) -> Enum.map(options, &{&1, &1})
      _other -> []
    end
  end

  defp select_options(_field), do: []

  defp media_fields(fields) do
    Enum.filter(fields, &media_field?/1)
  end

  defp media_field?(%ContentTypeField{field_type: type}),
    do: type in ["image", "video", "gallery"]

  defp media_upload_name(%ContentTypeField{id: id}) when is_binary(id), do: "payload_media_#{id}"
  defp media_upload_name(%ContentTypeField{field_key: key}), do: "payload_media_#{key}"

  defp media_accept(%ContentTypeField{field_type: "video"}), do: ~w(.mp4 .webm .mov)
  defp media_accept(_field), do: ~w(.jpg .jpeg .png .gif .webp .svg)

  defp media_max_file_size(%ContentTypeField{field_type: "video"}), do: 50_000_000
  defp media_max_file_size(_field), do: 5_000_000

  defp media_directory(%ContentTypeField{field_type: "video"}), do: "videos"
  defp media_directory(_field), do: "images"

  defp media_max_entries(%ContentTypeField{field_type: "gallery"}), do: 10
  defp media_max_entries(_field), do: 1

  defp media_upload_label(%ContentTypeField{field_type: "gallery"}), do: "gallery images"
  defp media_upload_label(%ContentTypeField{field_type: type}), do: String.downcase(type)

  defp safe_map(value) when is_map(value), do: value
  defp safe_map(_value), do: %{}

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
