# SQL Server setup samples

Ref: [Stack Overflow article](https://dba.stackexchange.com/questions/53815/clustering-vs-transactional-replication-vs-availability-groups)

## Replication vs High Availability

### SQL Server Failover Cluster Instance

**What is highly available?** The entire instance. That includes all server-objects (logins, SQL Server Agent jobs, etc.). This also includes databases and their containing entities. It's a great solution for highly available SQL Server instances, because that is going to be the level of containment with this given solution.

**What about reporting?** None, NULL, nonexistent. A failover cluster instance has an active node delivering the cluster group containing the instance, VNN, etc. and all other nodes are passive, sitting idle (as far as the current cluster group is concerned) and waiting for a failover.

**What happens when there is failover?** The downtime for an FCI is going to be determined by the amount of time that the passive node takes to grab the cluster resource and bring the SQL Server instance in a running state. This is typically minimal in time.

**Any client abstraction?** Yes, this is going to be innately built in with the virtual network name for the failover cluster instance. This will always point to the active node that is currently delivering the SQL Server cluster resource.

### AlwaysOn Availability Groups

**What is highly available?** An availability group is going to be the logical containment of high availability here, whereas an availability group consists of a number of databases and a virtual network name (the listener, an optional cluster resource). It is worth noting that server objects such as logins and SQL Server Agent jobs will not be part of the HA solution, and special consideration needs to be taken to ensure that these are properly implemented with an availability group. Not an overly burdening requirement, but needs to be cared for.

**What about reporting?** This is a great solution for reporting, although I probably wouldn't use a synchronous replica as my reporting instance. There are two commit relationships, synchronous and asynchronous. In my opinion and from what I've seen in practice, is that your synchronous secondary replica is there waiting for a disaster. Think of it as that replica that's ready to take a no-data-loss failover in the event of an issue. Then there are asynchronous replicas that can handle that reporting workload. You aren't using this replica as the aforementioned solution, but moreso for things like reporting. Reporting workloads can be pointed to this replica (either directly, or indirectly through read-only routing via the listener).

**What happens when there is failover?** For a synchronous commit secondary replica that is paired with automatic failover, this will be the replica role state change from SECONDARY_NORMAL to PRIMARY_NORMAL. In order for there to be automatic failover, you need to have a synchronous secondary replica that is currently synchronized, and what's implemented is the Flexible Failover Policy to determine when in fact this failover should occur. That policy is indeed configurable.

**Any client abstraction?** Yes, you could optionally configure an AlwaysOn Availability Group listener. This is basically just a virtual network name (can be seen through WSFC as a cluster resource in the AG's cluster group) that points to the current primary replica. This is a key part of shifting your reporting workload around, as well as setting up a read-only routing list on any servers that you want to redirect ReadOnly traffic (this is set through the connection string, with the .NET Framework Provider for SQL Server, this will be the Application Intent parameter, set to ReadOnly). You would also need to set a read-only routing URL for each replica that you want to receive this reporting workload while in the secondary replica role.

### Transactional Replication

**What is highly available?** This is arguable, but I'm going to say nothing. I don't see replication as a high availability solution whatsoever. Yes, data modifications are being pushed to subscribers but we're talking at the publication/article level. This is going to be a subset of the data (could include all the data, but that won't be enforced. I.e. you create a new table in the publisher database, and that will not automatically be pushed to the subscribers). As far as HA goes, this is bottom-of-the-barrel and I will not group it in there with a rock-solid HA solution.

**What about reporting?** A great solution for reporting on a subset of data, no question about that. If you have a 1 TB database that is highly transactional and you want to keep that reporting workload off the OLTP database, transactional replication is a great way to push a subset of data to a subscriber (or subscribers) for the reporting workload. What happens if out of that 1 TB of data your reporting workload is only about 50 GB? This is a smart solution, and relatively configurable to meet your business needs.

### Summary

What it boils down to are a handful of questions that need to be answered (partly by the business):

* What needs to be highly available?
* What does the SLA dictate for HA/DR?
* What kind of reporting will be taking place and what latencies are acceptable?
* What do we need to handle with geographically dispersed HA? (storage replication is expensive, but a must with an FCI. AGs don't require shared storage from standalone instances, and you could use a file share witness for quorum potentially eliminating the need for shared storage)

## In practise

### Through a High Availability Group

1. [Readonly Replicas through HA](./read-replicas-ha-docker/readme.md)
1. ~~TDE Database encryption in HA~~
1. ~~Setup failover~~

### Trhough Replication

1. [Transaction replication](./mssql-replication-docker/readme.md)
1. ~~Setup example replication snapshot~~
1. ~~Setup example replication peer-to-peer~~
1. ~~Setup example replication merge~~
