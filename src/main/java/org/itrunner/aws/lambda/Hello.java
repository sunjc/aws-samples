package org.itrunner.aws.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import org.itrunner.aws.sns.SnsUtil;
import org.itrunner.aws.sqs.JsonUtil;
import org.itrunner.aws.sqs.MessageBody;

import static org.itrunner.aws.util.Config.CONFIG;

public class Hello {

    public void handleRequest(SQSEvent event, Context context) {
        LambdaLogger logger = context.getLogger();
        logger.log("received : " + event.toString());

        try {
            MessageBody message = JsonUtil.parse(event.getRecords().get(0).getBody(), MessageBody.class);
            // do something
        } catch (Exception e) {
            logger.log(e.getMessage());
            SnsUtil.publish(CONFIG.getSnsTopicArn(), e.getMessage(), "Lambda Error");
        }
    }

}