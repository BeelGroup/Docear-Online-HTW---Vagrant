package common;

import org.apache.zookeeper.CreateMode;
import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.ZooDefs.Ids;
import org.apache.zookeeper.data.Stat;

public class CreateGroupWatcher extends ConnectionWatcher {

    public void create(String groupName) throws KeeperException, InterruptedException
    {
        String path = "/" + groupName;

        final boolean nodeExists = null != zk.exists(path, false);
        if (nodeExists) {
            System.out.println("already exists " + path);
        } else {
            String createdPath = zk.create(path, null/*data*/, Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
            System.out.println("Created " + createdPath);
        }


    }
}