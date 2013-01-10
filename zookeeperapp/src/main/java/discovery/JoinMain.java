package discovery;

import common.CreateEphemeralGroupWatcher;
import common.CreateGroupWatcher;
import org.apache.zookeeper.KeeperException;

import java.io.IOException;
import java.io.InputStreamReader;

public class JoinMain {
    public static final String ROOT_NODE_DOCEAR_INSTANCES = "/fakedocearinstances";

    public static void main(String[] args) throws InterruptedException, IOException, KeeperException {


        final String connectionString = "127.0.0.1" + ":" + 2181;

        createParent(connectionString);

        CreateEphemeralGroupWatcher createGroup = new CreateEphemeralGroupWatcher();


        String id = "noIdGiven";
        if (args.length > 0) {
            id = args[0];
        }

        createGroup.connect(connectionString);
        createGroup.create(ROOT_NODE_DOCEAR_INSTANCES + "/" + id);
//        createGroup.close();

        //if the application terminates, the ephemeral node disappears
        System.out.println("press enter to quit group " + id);
        new InputStreamReader(System.in).read();
    }

    private static void createParent(String connectionString) throws KeeperException, InterruptedException, IOException {
        CreateGroupWatcher createGroup = new CreateGroupWatcher();
        createGroup.connect(connectionString);
        createGroup.create(ROOT_NODE_DOCEAR_INSTANCES.substring(1));//remove first slash
        createGroup.close();
    }
}
