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
        @client = Aws::S3::Client.new(
          region: @target.aws_region,
          credentials: Aws::Credentials.new(@target.aws_id, @target.aws_secret),
          http_wire_trace: @debug
          )
      end

      def size_if_exists target
        log_debug "size_if_exists [#{target.path}]"
        object = @client.get_object(bucket: target.aws_bucket, key: target.path)
      rescue Aws::S3::Errors::NotFound => e
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

        # Compute parameters
        file_size     = file.size
        parts_size    = compute_parts_size(file_size)
        parts_count   = (file_size.to_f / parts_size).ceil
        log_debug "upload_multipart", {
          file_size:    format_bytes(file_size, "B"),
          parts_size:   format_bytes(parts_size, "B"),
          parts_count:  parts_count
          }

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

      def compute_parts_size filesize
        # Initial part size is minimal
        partsize_mini = JOB_S3_MIN_PART

        # Other partsize if too many blocks
        partsize_bigf = (filesize.to_f / JOB_S3_MAX_COUNT).ceil

        # Decide
        return [partsize_mini, partsize_bigf].max
      end

    end
  end
end