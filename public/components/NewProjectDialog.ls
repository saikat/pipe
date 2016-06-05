{map, zip, last, concat-map, id} = require \prelude-ls
{DOM:{div}, create-class, create-factory} = require \react
require! \../../config.ls
DataSourceCuePopup = create-factory require \./DataSourceCuePopup.ls
LabelledDropdown = create-factory require \./LabelledDropdown.ls
SimpleButton = create-factory require \./SimpleButton.ls
LabelledTextField = create-factory require \./LabelledTextField.ls
AceEditor = create-factory require \./AceEditor.ls
DataSourceCuePopup = create-factory require \./DataSourceCuePopup.ls

fold-obj-to-list = (f, object) -->
  [f key, value for key, value of object]

connections-to-data-sources = (connections) ->
    connections
    |> fold-obj-to-list (query-type, v) -> 
        v
        |> fold-obj-to-list (connection-name, connection) -> 
            {
                
                query-type
                connection-name
                connection
                
            }
    |> concat-map id


data-sources-to-connections = (data-sources) ->
    data-sources
    |> group-by (.queryType)
    |> Obj.map group-by (.connection-name)
    |> Obj.map Obj.map (.0.connection)


module.exports = create-class do 
    render: ->
        console.log \NewProjectDialog
        div do
            null
            LabelledTextField do
                label: 'Project Name'
                value: @props.project.title or ""
                on-change: (value) ~> 
                    @props.on-change {} <<< @props.project <<< title: value
            
            LabelledDropdown do
                label: 'Permissions'
                value: @props.project.permission
                options: <[private publicReadable publicExecutable publicReadableAndExecutable]> |> map -> {label: it, value: it}
                on-change: (value) ~>
                    @props.on-change {} <<< @props.project <<< permission: value

            @state.data-sources
            |> (`zip` [0 til @state.data-sources.length])
            |> map ([d, i]) ~>
                # DATASOURCE POPUP
                div {key: "data-source-#{i}"}, 
                    if d.complete  then 
                        div null, 
                            "#{d.connection-name}" 
                            SimpleButton do
                                on-click: ~> 
                                    @state.data-sources[i].complete = false
                                    @set-state data-sources: @state.data-sources
                                \Edit
                    else
                        div null,
                            SimpleButton do
                                on-click: ~> 
                                    @state.data-sources.splice i, 1
                                    @set-state data-sources: @state.data-sources
                                \-
                            DataSourceCuePopup do
                                supported-connection-kinds: <[complete connection-string]>
                                data-source-cue: d
                                project-id: @props.project-id
                                left: -> 0
                                on-change: (data-source-cue) ~> 
                                    console.log data-source-cue.complete, data-source-cue, i
                                    @state.data-sources[i] = data-source-cue
                                    @set-state data-sources: @state.data-sources

            SimpleButton do
                on-click: ~> 
                    @set-state data-sources: @state.data-sources ++ [
                        {} <<< ((last @state.data-sources) ? @state.default-data-source) <<< complete: false
                    ]
                \+

            SimpleButton do
                on-click: ~> 
                    @props.on-change {} <<< @props.project <<< connections: data-sources-to-connections @state.data-sources
                "Create Project #{@props.project.title}"
 
                    
    component-will-receive-props: (props) ->
        @set-state data-sources: [default-data-source] ++ connections-to-data-sources @props.project.connections

    # get-initial-state :: a -> UIState
    get-initial-state: ->  
        default-data-source = 
            connection-name: ''
            query-type: 'mongodb'
            connection-kind: 'complete'
            connection: {}
        data-sources: []
        # because the input json in the box is not always valid, use this to store invalid json
        connections-json: null
        default-data-source: default-data-source