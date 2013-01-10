package zookeeper;

import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.Watcher.Event.KeeperState;
import org.apache.zookeeper.ZooKeeper;
import play.Logger;

import java.io.IOException;
import java.util.concurrent.CountDownLatch;

public class ConnectionWatcher implements Watcher {

    protected ZooKeeper zk;
    private CountDownLatch connectedSignal = new CountDownLatch(1);

    public void connect(String hosts) throws IOException, InterruptedException {
        Logger.debug("try to start server");
        zk = new ZooKeeper(hosts, 2000, this);
        Logger.debug("wait for server start");
        connectedSignal.await();
        Logger.debug("server started");
    }

    @Override
    public void process(WatchedEvent event) {
        Logger.debug("process(WatchedEvent event)");
        if (event.getState() == KeeperState.SyncConnected) {
            connectedSignal.countDown();
        }
    }

    public void close() throws InterruptedException {
        zk.close();
    }
}