import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Properties;

public class DbTest {
    public static void main(String[] args) {
        String url = "jdbc:postgresql://aws-1-ap-south-1.pooler.supabase.com:6543/postgres?prepareThreshold=0&sslmode=require&gssEncMode=disable";
        Properties props = new Properties();
        props.setProperty("user", "postgres.szgvnurzdglflmdabjol");
        props.setProperty("password", "EG/2022/5006/15/19/83");

        System.out.println("Connecting to pooler with gssEncMode=disable " + url + " ...");
        try (Connection conn = DriverManager.getConnection(url, props)) {
            System.out.println("Connected successfully!");
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT NOW()")) {
                if (rs.next()) {
                    System.out.println("Query Result: " + rs.getString(1));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
