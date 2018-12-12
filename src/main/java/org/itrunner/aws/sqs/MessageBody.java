package org.itrunner.aws.sqs;

public class MessageBody {
    private String content;
    private String date;

    public MessageBody() {
    }

    public MessageBody(String content, String date) {
        this.content = content;
        this.date = date;
    }

    public String getContent() {
        return content;
    }

    public String getDate() {
        return date;
    }
}
