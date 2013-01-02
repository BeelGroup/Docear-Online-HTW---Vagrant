# Zookeeper
* ZooKeeper helps you build distributed applications.
* persisted data is distributed between multiple nodes
* writes are linear, good for strict ordering, bad for concurrency

## Feates that provides Zookeeper can built easily on top of it
* service locator, for us: find docear instances
* barrier for multiple server notes
* process events if new node shows op
* key value store

## Links
* http://zookeeper.apache.org/doc/current/
* http://zookeeper.apache.org/doc/current/zookeeperAdmin.html
* http://stackoverflow.com/questions/3662995/explaining-apache-zookeeper
* http://research.yahoo.com/files/ZooKeeper.pdf

#Demo App
## Start Demo
# Server: `sbt "run-main ZookeeperServerMain"`
# Client: `sbt "run-main ZookeeperClientMain"`
* some Code is from https://github.com/wdalmut/zookeeper-helloworld
* beware: version 3.4.4 of Zookeeper is buggy