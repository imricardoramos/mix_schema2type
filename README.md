# Schema2type

Convert Ecto Schemas to Typescript types

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mix_schema2type` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mix_schema2type, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/schema2type](https://hexdocs.pm/schema2type).

## Setup

You need to specify your main app name and the path to which you want your modules exported

```elixir
config :mix_schema2type,
  modules_app: :my_app,
  export_path: "assets/js/types/generated.ts",
  schema_names_map: [
    {MyModule, MyModuleNewName},
    {MyOtherModule, MyOtherModuleNewName}
  ],
  custom_types: [Ecto.MyCustomType]
```

## Usage

Simply run
```
mix schema2type
```
