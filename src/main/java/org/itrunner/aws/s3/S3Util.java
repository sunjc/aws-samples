package org.itrunner.aws.s3;

import com.amazonaws.HttpMethod;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.*;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.util.Date;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import static com.amazonaws.util.IOUtils.copy;

public class S3Util {
    private static AmazonS3 s3;

    static {
        s3 = AmazonS3ClientBuilder.standard().withRegion(Regions.CN_NORTH_1).build();
    }

    private S3Util() {
    }

    public static void selectCsvObjectContent(String bucketName, String csvObjectKey, String sql, String outputPath) throws Exception {
        SelectObjectContentRequest request = generateBaseCSVRequest(bucketName, csvObjectKey, sql);
        final AtomicBoolean isResultComplete = new AtomicBoolean(false);

        try (OutputStream fileOutputStream = new FileOutputStream(new File(outputPath));
             SelectObjectContentResult result = s3.selectObjectContent(request)) {
            InputStream resultInputStream = result.getPayload().getRecordsInputStream(
                    new SelectObjectContentEventVisitor() {
                        /*
                         * An End Event informs that the request has finished successfully.
                         */
                        @Override
                        public void visit(SelectObjectContentEvent.EndEvent event) {
                            isResultComplete.set(true);
                        }
                    }
            );

            copy(resultInputStream, fileOutputStream);
        }

        /*
         * The End Event indicates all matching records have been transmitted. If the End Event is not received, the results may be incomplete.
         */
        if (!isResultComplete.get()) {
            throw new Exception("S3 Select request was incomplete as End Event was not received.");
        }
    }

    private static SelectObjectContentRequest generateBaseCSVRequest(String bucket, String key, String query) {
        SelectObjectContentRequest request = new SelectObjectContentRequest();
        request.setBucketName(bucket);
        request.setKey(key);
        request.setExpression(query);
        request.setExpressionType(ExpressionType.SQL);

        InputSerialization inputSerialization = new InputSerialization();
        CSVInput csvInput = new CSVInput();
        csvInput.setFileHeaderInfo(FileHeaderInfo.USE);
        inputSerialization.setCsv(csvInput);
        inputSerialization.setCompressionType(CompressionType.NONE);
        request.setInputSerialization(inputSerialization);

        OutputSerialization outputSerialization = new OutputSerialization();
        outputSerialization.setCsv(new CSVOutput());
        request.setOutputSerialization(outputSerialization);

        return request;
    }

    public String generatePresignedUrl(String bucketName, String key, int minutes) {
        // Sets the expiration date
        Date expiration = new Date();
        long expTimeMillis = expiration.getTime();
        expTimeMillis += 1000 * 60 * minutes;
        expiration.setTime(expTimeMillis);

        // Generate the presigned URL.
        GeneratePresignedUrlRequest generatePresignedUrlRequest = new GeneratePresignedUrlRequest(bucketName, key).withMethod(HttpMethod.GET).withExpiration(expiration);
        URL url = s3.generatePresignedUrl(generatePresignedUrlRequest);

        return url.toString();
    }

    /**
     * Create a new S3 bucket - Amazon S3 bucket names are globally unique
     */
    public static Bucket createBucket(String bucketName) {
        return s3.createBucket(bucketName);
    }

    /**
     * List the buckets in your account
     */
    public static List<Bucket> listBuckets() {
        return s3.listBuckets();
    }

    /**
     * List objects in your bucket
     */
    public static ObjectListing listObjects(String bucketName) {
        return s3.listObjects(bucketName);
    }

    /**
     * List objects in your bucket by prefix
     */
    public static ObjectListing listObjects(String bucketName, String prefix) {
        return s3.listObjects(bucketName, prefix);
    }

    /**
     * Upload an object to your bucket
     */
    public static PutObjectResult putObject(String bucketName, String key, File file) {
        return s3.putObject(bucketName, key, file);
    }

    /**
     * Download an object - When you download an object, you get all of the object's metadata and a stream from which to read the contents.
     * It's important to read the contents of the stream as quickly as possibly since the data is streamed directly from Amazon S3 and your
     * network connection will remain open until you read all the data or close the input stream.
     */
    public static S3Object get(String bucketName, String key) {
        return s3.getObject(bucketName, key);
    }

    /**
     * Delete an object - Unless versioning has been turned on for your bucket, there is no way to undelete an object, so use caution when deleting objects.
     */
    public static void deleteObject(String bucketName, String key) {
        s3.deleteObject(bucketName, key);
    }

    /**
     * Delete a bucket - A bucket must be completely empty before it can be deleted, so remember to delete any objects from your buckets before
     * you try to delete them.
     */
    public static void deleteBucket(String bucketName) {
        s3.deleteBucket(bucketName);
    }
}