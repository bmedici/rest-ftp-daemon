require 'aws-sdk-resources'

# Handle sFTP transfers for Remote class
module RestFtpDaemon
  module Remote
    class RemoteS3 < RemoteBase

      MULTIPART_THRESHOLD_MB = 4

      # Class options
      attr_reader :client
      attr_reader :target

      def prepare
        @multipart_threshold = MULTIPART_THRESHOLD_MB.to_i * 1024 * 1024
        log_debug "RemoteS3.prepare target[#{@target.inspect}] #{@multipart_threshold}"
      end

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
        #s3 = Aws::S3::Client.new(http_wire_trace: true)
      end

      def size_if_exists target
        log_debug "RemoteS3.size_if_exists [#{target.path}]"

        # Update progress before
        bucket = @client.bucket(target.aws_bucket)
        object = bucket.object(target.path)
        # object = @client.get_object(bucket: target.aws_bucket, key: target.name)
        log_debug "content_length: #{object.content_length}"
      rescue Aws::S3::Errors::NotFound
        return false
      else
        return object.content_length
      end

      def upload source, target, use_temp_name = false, &callback
        # Push init
        raise RestFtpDaemon::AssertionFailed, "upload/client" if @client.nil?
        log_debug "RemoteS3.upload bucket[#{target.aws_bucket}] path[#{target.path}]"

        # Update progress before
        bucket = @client.bucket(target.aws_bucket)
        object = bucket.object(target.path)
        log_debug "RemoteS3.upload object[#{target.path}]"

        # Do the transfer
        object.upload_file(source.filepath, {
          multipart_threshold: @multipart_threshold
          })

        # Wait for transfer to complete
        object.wait_until_exists do |waiter|
          # waiter.delay = 1
          # # log_debug "- progress[#{progress}] total[#{total}]"
          # waiter.before_wait do |attempts, response|
          #   puts "#{attempts} made"
          #   puts response.error.inspect
          #   puts response.data.inspect
          # end
          # log_debug "- progress[] #{waiter.inspect}"
        end

        # Update progress after
        #yield target.size, target.name

        # Dump information about this file
        log_debug "RemoteS3.upload url[#{object.public_url}]"
        log_debug "RemoteS3.upload etag[#{object.etag}]"
        set_info :target_aws_public_url, object.public_url
        set_info :target_aws_etag, object.etag
      end

      def connected?
        !@client.nil?
      end

    end
  end
end