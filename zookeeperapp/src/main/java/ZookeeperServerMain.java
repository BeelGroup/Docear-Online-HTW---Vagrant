import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.server.quorum.QuorumPeerConfig;
import org.apache.zookeeper.server.quorum.QuorumPeerMain;

import java.io.IOException;

public class ZookeeperServerMain {
    public static void main(String[] args) {
        QuorumPeerMain.main(new String[]{"src/main/config/server.cfg"});
    }
}
