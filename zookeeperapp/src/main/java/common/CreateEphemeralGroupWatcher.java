package common;

import org.apache.zookeeper.CreateMode;
import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.ZooDefs;

import static org.apache.zookeeper.CreateMode.EPHEMERAL;
import static org.apache.zookeeper.ZooDefs.Ids.OPEN_ACL_UNSAFE;

public class CreateEphemeralGroupWatcher extends ConnectionWatcher {

    public static final byte[] EMPTY_DATA = new byte[0];

    public void create(final String path) throws KeeperException, InterruptedException
    {
        String createdPath = zk.create(path, EMPTY_DATA, OPEN_ACL_UNSAFE, EPHEMERAL);
        System.out.println("Created " + createdPath);
    }
}