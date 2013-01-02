import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.ZooKeeper;

import java.util.concurrent.CountDownLatch;

import java.io.IOException;
import org.apache.zookeeper.Watcher.Event.KeeperState;

public class ConnectionWatcher implements Watcher {

    protected ZooKeeper zk;
    private CountDownLatch connectedSignal = new CountDownLatch(1);

    public void connect(String hosts) throws IOException, InterruptedException
    {
        System.out.println("try to start server");
        zk = new ZooKeeper(hosts, 2000, this);
        System.out.println("wait for server start");
        connectedSignal.await();
        System.out.println("server started");
    }

    @Override
    public void process(WatchedEvent event) {
        System.out.println("process(WatchedEvent event)");
        if (event.getState() == KeeperState.SyncConnected) {
            connectedSignal.countDown();
        }
    }

    public void close() throws InterruptedException
    {
        zk.close();
    }
}