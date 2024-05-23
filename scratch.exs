commands

When you first create a portal

CreatePortal
  %{query_mod, from, args}
  From a child to a parent

  Adds portal_table and watcher_table rows in SorceryDb
  Adds a portal entry to the parent state, and packages the portal for the child
  msg = %{command: :portal_merge, from: self(), args: %{portal: child_portal}}
  
PortalUpdatesDetected
  %{args: %{portal_name, parent_pid}}
  From an unknown process to a child

  Probably middleware can go here at some point
  send(parent, %{command: :PortalFetch, portal_name, query, args, from})

PortalFetch
  %{portal_name, query, args, from}
  From a child to a parent

  data = state.store_adapter.run_query(query, args)
  updates sorcerydb ets tables
  send(%{command: :portal_merge, args: %{portal: portal, portal_name: portal_name}})

PortalMerge
  %{args: %{portal_name, parent_pid, portal}}
  From a parent to a child

  adds it to state.sorcery.portals_to_parent.parent.portal_name
  
RunMutation 
  %{args: %{mutation}}
  From a child to a parent

  Applies changes to Store
  gets a diff in return with real ids
  Submits the reverse query to get a list of pids
  sends %{command: PortalUpdatesDetected, portal_name, parent_pid}
