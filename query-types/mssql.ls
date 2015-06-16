{bindP, from-error-value-callback, new-promise, returnP, to-callback, with-cancel} = require \../async-ls
config = require \./../config
{concat-map, each, group-by, Obj, keys, map, obj-to-pairs} = require \prelude-ls
sql = require \mssql

execute-sql = (data-source, query) -->
    connection = null

    execute-sql-promise = new-promise (res, rej) ->
        connection := new sql.Connection data-source, (err) ->
            return rej err  if !!err 
            err, records <- (new sql.Request connection).query query
            connection.close!
            if !!err then rej err else res records

    execute-sql-promise `with-cancel` ->
        res, rej <- new-promise
        connection.close! if !!connection
        res \killed

# connections :: (CancellablePromise cp) => a -> cp b
export connections = ->
    returnP do 
        connections: (config?.connections?.mssql or {}) 
            |> obj-to-pairs
            |> map ([name, value]) -> {label: (value.label or name), value: name}

# keywords :: (CancellablePromise cp) => DataSource -> cp [String]
export keywords = (data-source) ->
    results <- bindP (execute-sql data-source, "SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS")    
    returnP <[SELECT GROUP BY TOP ORDER WITH DISTINCT INNER OUTER JOIN]> ++ (results
        |> group-by (.TABLE_SCHEMA)
        |> Obj.map group-by (.TABLE_NAME) 
        |> Obj.map Obj.map map (.COLUMN_NAME)
        |> Obj.map obj-to-pairs >> concat-map ([table, columns]) -> [table] ++ do -> columns |> map ("#{table}." +)
        |> obj-to-pairs
        |> concat-map (.1))

# get-context :: a -> Context
export get-context = ->
    {} <<< (require \./default-query-context.ls)!

# for executing a single mongodb query POSTed from client
# execute :: (CancellablePromise cp) => DataSource -> String -> CompiledQueryParameters -> cp result
export execute = (query-database, data-source, query, parameters) -->
    (Obj.keys parameters) |> each (key) ->
        query := query.replace "$#{key}$", parameters[key]
    execute-sql data-source, query

# default-document :: () -> Document
export default-document = -> 
    {
        query: """
        select top 100 * from 
        """
        transformation: "id"
        presentation: "json"
        parameters: ""
    }