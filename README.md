# Distillery AWS Example App

This application was forked and hacked on to develop a dynamic, multi-node registry and communication pattern.

## Prerequisites

- Install [AWS CLI](client: https://docs.aws.amazon.com/cli/latest/userguide/install-macos.html)

## Running a Multi-Node Communciation Test Locally

You need to have PostgreSQL installed locally. Adjust the configuration as needed.

Assemble the application and establish the database structure:

- `mix do deps.get, compile`
- `cd apps/engine`
- `DATABASE_HOST=localhost mix ecto.create`
- `DATABASE_HOST=localhost mix ecto.migrate`

### Start Engine (the database app) as :node2

Open a terminal window and go to `%project_path%/aws-dist-test/apps/engine`.

```
DATABASE_HOST=localhost APP_PORT=4001 iex --sname node2@localhost -S mix phx.server
```

### Start Web (the web app) as :node1

Open a terminal window and go to `%project_path%/aws-dist-test/apps/web`.

```
DATABASE_HOST=localhost APP_PORT=4000 iex --sname node1@localhost -S mix phx.server
```

The two nodes connect because the `web` application uses [libcluster](https://github.com/bitwalker/libcluster) and has the following in `web/config.exs`:

```
config :services, Services.Cluster,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: [:node2@localhost, :node3@localhost]]
    ]
  ]
```

If [libcluster](https://github.com/bitwalker/libcluster) wasn't used, you could manually connect the nodes through `Node.connect/1`.

```
iex(node1@localhost)1> Node.connect :node2@localhost
```

### Test the Cross-Node Communication

Insert at least one record into the `todos` table in the database:
```
$ psql -d example_web_dev
example_web_dev=# insert into todos (title, completed, inserted_at, updated_at) values ('My New Todo', FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
example_web_dev=# \q
```

To see the cross-node communication in action, call the `Services.Todos.all/1` function from the node running the `web` application.

```
iex(node1@localhost)1> Services.Todos.all
```

You should see a response from the function in the terminal running the `web` application.

```
{:ok,
 [
   %{
     __struct__: Engine.Todo,
     completed: false,
     id: 20,
     inserted_at: #DateTime<2019-04-05 13:30:48Z>,
     title: "take out the garbage",
     updated_at: #DateTime<2019-04-05 13:30:48Z>
   },
   %{
     __struct__: Engine.Todo,
     completed: false,
     id: 21,
     inserted_at: #DateTime<2019-04-05 13:30:52Z>,
     title: "dream big",
     updated_at: #DateTime<2019-04-05 13:30:52Z>
   },
   %{
     __struct__: Engine.Todo,
     completed: false,
     id: 22,
     inserted_at: #DateTime<2019-04-05 13:30:54Z>,
     title: "floss",
     updated_at: #DateTime<2019-04-05 13:30:54Z>
   }
 ]}
```

If you look at the terminal running the `engine` application, you should see the IO output from the database query.

```
08:44:56.276 [debug] QUERY OK source="todos" db=13.6ms
SELECT t0."id", t0."title", t0."completed", t0."inserted_at", t0."updated_at" FROM "todos" AS t0 []
```

Successful demonstration of how one node can talk to another node. From here, we can build out a pattern so that modules we intend to share across applications can be accessed as part of a cluster of nodes on multiple VMs, rather than all deployed together in the same VM.
