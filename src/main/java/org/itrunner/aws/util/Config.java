package org.itrunner.aws.util;

import java.io.FileReader;
import java.io.IOException;
import java.util.Properties;

public enum Config {
    CONFIG;

    private static final String CONFIG_FILE = "config.properties";

    private Properties properties;

    Config() {
        properties = new Properties();
        try {
            properties.load(new FileReader(getJarPath() + CONFIG_FILE));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static String getJarPath() {
        String path = Config.class.getProtectionDomain().getCodeSource().getLocation().getPath();
        if (path.endsWith(".jar")) {
            path = path.substring(0, path.lastIndexOf("/") + 1);
        }
        return path;
    }

    public String getSqsUrl() {
        return properties.getProperty("sqs.url");
    }

    public Integer getSqsReceiveMaxNum() {
        return Integer.parseInt(properties.getProperty("sqs.receive.maxNumber"));
    }

    public Integer getSqsReceiveWaitTime() {
        return Integer.parseInt(properties.getProperty("sqs.receive.waitTime"));
    }

    public String getSnsTopicArn() {
        return properties.getProperty("sns.topic.arn");
    }

    public String getDbUrl() {
        return properties.getProperty("db.url");
    }

    public String getDbUsername() {
        return properties.getProperty("db.username");
    }

    public String getDbPassword() {
        return properties.getProperty("db.password");
    }
}
