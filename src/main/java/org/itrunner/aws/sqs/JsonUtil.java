package org.itrunner.aws.sqs;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;

public final class JsonUtil {
    private static ObjectMapper mapper = new ObjectMapper();

    private JsonUtil() {
    }

    public static String generate(Object object) throws JsonProcessingException {
        return mapper.writeValueAsString(object);
    }

    public static <T> T parse(String content, Class<T> valueType) throws IOException {
        return mapper.readValue(content, valueType);
    }
}
