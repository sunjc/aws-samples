package org.itrunner.aws.util;

import oracle.jdbc.driver.OracleDriver;
import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import static org.itrunner.aws.util.Config.CONFIG;

public class ConnectionUtil {
    private static final Logger LOG = LogManager.getLogger(ConnectionUtil.class);

    private ConnectionUtil() {
    }

    public static Connection getConnection() throws SQLException, ClassNotFoundException {
        return getConnection(CONFIG.getDbUrl(), CONFIG.getDbUsername(), CONFIG.getDbPassword());
    }

    public static Connection getConnection(String url, String username, String password) throws ClassNotFoundException, SQLException {
        Class.forName(OracleDriver.class.getName());
        Connection connection = DriverManager.getConnection(url, username, password);
        connection.setAutoCommit(false);
        return connection;
    }

    public static void closeConnection(Connection connection) {
        try {
            if (connection != null) {
                connection.setAutoCommit(true);
                connection.close();
            }
        } catch (SQLException e) {
            LOG.log(Level.ERROR, e.getMessage());
        }
    }

    public static void rollback(Connection connection) {
        if (connection != null) {
            try {
                connection.rollback();
                connection.setAutoCommit(true);
            } catch (SQLException e) {
                LOG.log(Level.ERROR, e.getMessage());
            }
        }
    }
}
