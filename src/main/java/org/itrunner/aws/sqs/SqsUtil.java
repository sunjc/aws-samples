package org.itrunner.aws.sqs;

import com.amazonaws.regions.Regions;
import com.amazonaws.services.sqs.AmazonSQS;
import com.amazonaws.services.sqs.AmazonSQSClientBuilder;
import com.amazonaws.services.sqs.model.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.itrunner.aws.util.Config;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class SqsUtil {
    private static final String ARN_ATTRIBUTE_NAME = "QueueArn";
    private static final Logger LOG = LogManager.getLogger(SqsUtil.class);
    private static AmazonSQS sqs;

    static {
        sqs = AmazonSQSClientBuilder.standard().withRegion(Regions.CN_NORTH_1).build();
    }

    private SqsUtil() {
    }

    public static String createQueue(String queueName) {
        LOG.info("Creating a new SQS queue called " + queueName);

        CreateQueueRequest createQueueRequest = new CreateQueueRequest(queueName);
        Map<String, String> attributes = new HashMap<>();
        attributes.put("ReceiveMessageWaitTimeSeconds", "5");
        createQueueRequest.withAttributes(attributes);

        return sqs.createQueue(createQueueRequest).getQueueUrl();
    }

    public static String createDeadLetterQueue(String queueName) {
        String queueUrl = createQueue(queueName);
        return getQueueArn(queueUrl);
    }

    public static void configDeadLetterQueue(String queueUrl, String deadLetterQueueArn) {
        LOG.info("Config dead letter queue for " + queueUrl);

        SetQueueAttributesRequest queueAttributes = new SetQueueAttributesRequest();
        Map<String, String> attributes = new HashMap<>();
        attributes.put("RedrivePolicy", "{\"maxReceiveCount\":\"5\", \"deadLetterTargetArn\":\"" + deadLetterQueueArn + "\"}");
        queueAttributes.setAttributes(attributes);
        queueAttributes.setQueueUrl(queueUrl);

        sqs.setQueueAttributes(queueAttributes);
    }

    public static void sendMessage(String queueUrl, String message) {
        LOG.info("Sending a message to " + queueUrl);

        SendMessageRequest request = new SendMessageRequest();
        request.withQueueUrl(queueUrl);
        request.withMessageBody(message);
        sqs.sendMessage(request);
    }

    public static List<Message> receiveMessages(String queueUrl) {
        LOG.info("Receiving messages from " + queueUrl);

        ReceiveMessageRequest receiveMessageRequest = new ReceiveMessageRequest(queueUrl);
        receiveMessageRequest.setMaxNumberOfMessages(Config.CONFIG.getSqsReceiveMaxNum());
        receiveMessageRequest.withWaitTimeSeconds(Config.CONFIG.getSqsReceiveWaitTime());

        return sqs.receiveMessage(receiveMessageRequest).getMessages();
    }

    public static void deleteMessage(String queueUrl, String receiptHandle) {
        sqs.deleteMessage(new DeleteMessageRequest(queueUrl, receiptHandle));
    }

    public static void deleteQueue(String queueUrl) {
        LOG.info("Deleting the queue " + queueUrl);
        sqs.deleteQueue(new DeleteQueueRequest(queueUrl));
    }

    public static String getQueueArn(String queueUrl) {
        List<String> attributes = new ArrayList<>();
        attributes.add(ARN_ATTRIBUTE_NAME);
        GetQueueAttributesResult queueAttributes = sqs.getQueueAttributes(queueUrl, attributes);
        return queueAttributes.getAttributes().get(ARN_ATTRIBUTE_NAME);
    }
}