require 'aws-sdk-resources'

# Handle sFTP transfers for Remote class
module RestFtpDaemon
  module Remote
    class RemoteS3 < RemoteBase
      MULTIPART_THRESHOLD_MB = 4

      # Class options
      attr_reader :client
      attr_reader :target

      # def prepare
      # end

      def connect
        super

        # Connect init
        log_debug "connect region[#{target.aws_region}] id[#{target.aws_id}]"

        # Connect remote server
        @client = Aws::S3::Resource.new(
          region: @target.aws_region,
          credentials: Aws::Credentials.new(@target.aws_id, @target.aws_secret),
          http_wire_trace: @debug
          )
      end

      def size_if_exists target
        log_debug "RemoteS3.size_if_exists [#{target.path}]"

        # Update progress before
        bucket = @client.bucket(target.aws_bucket)
        object = bucket.object(target.path)
        log_debug "content_length: #{object.content_length}"
      rescue Aws::S3::Errors::NotFound
        #log_debug "content_length: #{object.content_length}"
        return false
      else
        return object.content_length
      end

      def upload source, target, use_temp_name = false, &callback
        # Push init
        raise RestFtpDaemon::AssertionFailed, "upload/client" if @client.nil?
        log_debug "RemoteS3.upload bucket[#{target.aws_bucket}] path[#{target.path}]"
        # Do the transfer, handing file to the correct method
        File.open(source.filepath, 'r', encoding: 'BINARY') do |file|
          if file.size >= JOB_S3_MIN_PART
            upload_multipart  file, target.aws_bucket, target.path, target.name, &callback
          else
            upload_onefile    file, target.aws_bucket, target.path, target.name, &callback
          end
        end

        # Update progress before
        bucket = @client.bucket(target.aws_bucket)
        object = bucket.object(target.path)
        log_debug "RemoteS3.upload object[#{target.path}]"

        # Do the transfer
        object.upload_file(source.filepath, {
          multipart_threshold: @multipart_threshold
          })
      def connected?
        !@client.nil?
      end

    private

      def upload_onefile file, s3_bucket, s3_path, s3_name, &callback
        log_debug "upload_onefile"
        @client.put_object(bucket: s3_bucket, key: s3_path, body: file)
      end

      def upload_multipart file, s3_bucket, s3_path, s3_name, &callback
        # Init
        end

        # Update progress after
        #yield target.size, target.name

        # Dump information about this file
        log_debug "RemoteS3.upload url[#{object.public_url}]"
        log_debug "RemoteS3.upload etag[#{object.etag}]"
        set_info :target_aws_public_url, object.public_url
        set_info :target_aws_etag, object.etag
      end
      end  

 

    end
  end
end