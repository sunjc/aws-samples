package org.itrunner.aws.sns;

import com.amazonaws.regions.Regions;
import com.amazonaws.services.sns.AmazonSNS;
import com.amazonaws.services.sns.AmazonSNSClientBuilder;
import com.amazonaws.services.sns.model.*;

public class SnsUtil {
    private static AmazonSNS sns;

    static {
        sns = AmazonSNSClientBuilder.standard().withRegion(Regions.CN_NORTH_1).build();
    }

    private SnsUtil() {
    }

    /**
     * Creates a topic to which notifications can be published
     */
    public static CreateTopicResult createTopic(String name) {
        return sns.createTopic(name);
    }

    /**
     * Deletes a topic and all its subscriptions
     */
    public static DeleteTopicResult deleteTopic(String topicArn) {
        return sns.deleteTopic(topicArn);
    }

    /**
     * Prepares to subscribe an endpoint by sending the endpoint a confirmation message
     */
    public static SubscribeResult subscribe(String topicArn, String protocol, String endpoint) {
        return sns.subscribe(topicArn, protocol, endpoint);
    }

    /**
     * Deletes a subscription
     */
    public static UnsubscribeResult unsubscribe(String subscriptionArn) {
        return sns.unsubscribe(subscriptionArn);
    }

    /**
     * Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action
     */
    public static ConfirmSubscriptionResult confirmSubscription(String topicArn, String token) {
        return sns.confirmSubscription(topicArn, token);
    }

    /**
     * Sends a message to an Amazon SNS topic
     */
    public static PublishResult publish(String topicArn, String message, String subject) {
        return sns.publish(topicArn, message, subject);
    }
}
