## Default Permission

Default gen-ui permissions: read + chat intents. Mutating entity commands require the gen-ui:allow-write set explicitly.

#### This default permission set includes the following:

- `allow-chat-send`
- `allow-entity-list`
- `allow-entity-get`
- `allow-memory-search`
- `allow-graph-expand`

## Permission Table

<table>
<tr>
<th>Identifier</th>
<th>Description</th>
</tr>


<tr>
<td>

`gen-ui:allow-chat-send`

</td>
<td>

Enables the chat_send command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:deny-chat-send`

</td>
<td>

Denies the chat_send command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:allow-entity-create`

</td>
<td>

Enables the entity_create command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:deny-entity-create`

</td>
<td>

Denies the entity_create command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:allow-entity-delete`

</td>
<td>

Enables the entity_delete command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:deny-entity-delete`

</td>
<td>

Denies the entity_delete command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:allow-entity-get`

</td>
<td>

Enables the entity_get command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:deny-entity-get`

</td>
<td>

Denies the entity_get command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:allow-entity-list`

</td>
<td>

Enables the entity_list command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:deny-entity-list`

</td>
<td>

Denies the entity_list command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:allow-entity-update`

</td>
<td>

Enables the entity_update command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:deny-entity-update`

</td>
<td>

Denies the entity_update command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:allow-graph-expand`

</td>
<td>

Enables the graph_expand command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:deny-graph-expand`

</td>
<td>

Denies the graph_expand command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:allow-memory-search`

</td>
<td>

Enables the memory_search command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:deny-memory-search`

</td>
<td>

Denies the memory_search command without any pre-configured scope.

</td>
</tr>

<tr>
<td>

`gen-ui:allow-write`

</td>
<td>

Allow entity create/update/delete. Grant only to capabilities that own writes.

</td>
</tr>
</table>
