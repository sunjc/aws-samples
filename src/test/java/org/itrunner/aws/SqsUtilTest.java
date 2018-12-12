package org.itrunner.aws;

import org.itrunner.aws.sqs.SqsUtil;

public class SqsUtilTest {
    public static void main(String[] args) {
        String deadLetterQueueArn = SqsUtil.createDeadLetterQueue("DeadLetterQueue");
        String queueUrl = SqsUtil.createQueue("TaskQueue");
        SqsUtil.configDeadLetterQueue(queueUrl, deadLetterQueueArn);
        for (int i = 0; i < 6; i++) {
            SqsUtil.sendMessage(queueUrl, "Hello COCO " + i);
        }
        SqsUtil.receiveMessages(queueUrl);

        SqsUtil.deleteQueue(queueUrl);
    }
}
