import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.ZooKeeperMain;

import java.io.IOException;

public class ZookeeperClientMain {
    public static void main(String[] args) throws InterruptedException, IOException, KeeperException {
        final String connectionString = "127.0.0.1" + ":" + 2181;
        CreateGroupWatcher createGroup = new CreateGroupWatcher();
        createGroup.connect(connectionString);
        createGroup.create("abc");
        createGroup.close();
    }
}

//  ZooKeeperMain.main(new String[]{"-server", connectionString}); ist not helpful