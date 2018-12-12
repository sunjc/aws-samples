package org.itrunner.aws;

import com.amazonaws.services.sns.model.CreateTopicResult;
import com.amazonaws.services.sns.model.SubscribeResult;

import static org.itrunner.aws.sns.SnsUtil.*;

public class SnsUtilTest {
    public static void main(String[] args) {
        CreateTopicResult topic = createTopic("test-topic");
        SubscribeResult subscribe = subscribe(topic.getTopicArn(), "email", "sunjc@iata.org");
//        confirmSubscription("arn:aws-cn:sns:cn-north-1:891245299999:test-topic", "...");
//        publish("arn:aws-cn:sns:cn-north-1:891245299999:test-topic", "Hello COCO", "Hello COCO");
//        unsubscribe("arn:aws-cn:sns:cn-north-1:891245299999:test-topic:bcd65f82-ae54-4604-a763-30b7ff877e8a");
//        deleteTopic("arn:aws-cn:sns:cn-north-1:891245299999:test-topic");
    }
}
