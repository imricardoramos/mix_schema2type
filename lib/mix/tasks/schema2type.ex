defmodule Mix.Tasks.Schema2type do
  use Mix.Task

  @modules_app Application.get_env(:mix_schema2type, :modules_app)
  @schema_names_map Application.get_env(:mix_schema2type, :schema_names_map)
  @custom_types Application.get_env(:mix_schema2type, :custom_types)

  def run(_) do
    export_path = Application.get_env(:mix_schema2type, :export_path)

    if is_nil(export_path) do
      IO.puts("You must specify an export path")
    else
      Mix.Task.run("app.start")
      {:ok, modules} = :application.get_key(@modules_app, :modules)

      file_contents =
        modules
        |> find_schemas_from_modules()
        |> map_fields_for_schemas()
        |> prepend_custom_types(@custom_types)
        |> Enum.map(&convert_to_ts/1)
        |> List.foldl("", fn string, acc -> acc <> string end)
        |> put_eslint_ignore()

      File.mkdir_p!(Path.dirname(export_path))
      File.write!(export_path, file_contents)
      IO.puts("Typescript types generated!")
      IO.puts("Export path: #{export_path}")
    end
  end

  defp put_eslint_ignore(file_contents) do
    "/* eslint-disable no-unused-vars, @typescript-eslint/no-unused-vars*/\n" <> file_contents
  end

  defp prepend_custom_types(types_list, custom_types) do
    Enum.map(custom_types, &{&1, &1.type()}) ++ types_list
  end

  defp map_name(name) do
    Enum.find_value(@schema_names_map, &if(elem(&1, 0) == name, do: elem(&1, 1))) || name
  end

  defp map_fields_for_schemas(schemas) do
    Enum.map(schemas, fn schema ->
      fields =
        schema.__schema__(:fields)
        |> Enum.map(fn field ->
          {field, schema.__schema__(:type, field)}
        end)

      {map_name(schema), fields}
    end)
  end

  defp find_schemas_from_modules(modules) do
    Enum.filter(modules, fn module ->
      :erlang.function_exported(module, :__info__, 1) &&
        {:__schema__, 1} in module.__info__(:functions)
    end)
  end

  defp convert_to_ts({module, type}) when is_atom(type) do
    type_name = module |> module_name_last_segment()
    type = "#{map_ecto_type_to_typescript(type)};\n"

    """
    type #{type_name} = #{type}
    """
  end

  defp convert_to_ts({module, fields}) when is_list(fields) do
    type_name = module |> module_name_last_segment()

    types =
      Enum.map(fields, fn {field, type} ->
        "  #{pascalize(to_string(field))}: #{map_ecto_type_to_typescript(type)};\n"
      end)

    "type #{type_name} = { \n#{types}}\n\n"
  end

  defp map_ecto_type_to_typescript(type) do
    case type do
      :string ->
        "string"

      :uuid ->
        "string"

      :integer ->
        "number"

      :float ->
        "number"

      :naive_datetime ->
        "Date"

      :utc_datetime ->
        "Date"

      {:array, type} ->
        "#{map_ecto_type_to_typescript(type)}[]"

      {:parameterized, Ecto.Embedded, %{cardinality: :many, related: type}} ->
        "#{map_ecto_type_to_typescript(type)}[]"

      {:parameterized, Ecto.Embedded, %{cardinality: :one, related: type}} ->
        "#{map_ecto_type_to_typescript(type)}"

      type ->
        module_name_last_segment(type)
    end
  end

  defp module_name_last_segment(module) do
    module |> map_name() |> to_string() |> String.split(".") |> List.last()
  end

  defp pascalize(string) do
    with <<first::utf8, rest::binary>> <- Macro.camelize(string) do
      String.downcase(<<first::utf8>>) <> rest
    end
  end
end
