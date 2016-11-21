require 'aws-sdk-resources'

# Handle sFTP transfers for Remote class
module RestFtpDaemon
  module Remote
    class RemoteS3 < RemoteBase
      include CommonHelpers

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
        log_debug "upload bucket[#{target.aws_bucket}] path[#{target.path}]"

        # Do the transfer, passing the file to the best method
        File.open(source.filepath, 'r', encoding: 'BINARY') do |file|
          if file.size >= JOB_S3_MIN_PART
            upload_multipart  file, target.aws_bucket, target.path, target.name, &callback
          else
            upload_onefile    file, target.aws_bucket, target.path, target.name, &callback
          end
        end

        # We're all set
        log_debug "RemoteS3.upload done"
      end

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
        current_part  = 1

        # Compute parameters
        file_size     = file.size
        parts_size    = compute_parts_size(file_size)
        parts_count   = (file_size.to_f / parts_size).ceil
        log_debug "upload_multipart", {
          file_size:    format_bytes(file_size, "B"),
          parts_size:   format_bytes(parts_size, "B"),
          parts_count:  parts_count
          }

        # Prepare basic opts
        options = {
          bucket: s3_bucket,
          key:    s3_path,
          }

        # Declare multipart upload
        mpu_create_response = @client.create_multipart_upload(options)
        options[:upload_id] = mpu_create_response.upload_id
        log_debug "created multipart: #{options[:upload_id]}"

        # Upload each part
        file.each_part(parts_size) do |part|
          # Prepare part upload
          opts = options.merge({
            body:        part,
            part_number: current_part,
            })
          log_debug "upload_part [#{current_part}/#{parts_count}]"
          resp = @client.upload_part(opts)  
          
          # Send progress info upwards
          yield parts_size, s3_name

          # Increment part number
          current_part += 1
        end

        # Retrieve parts and complete upload
        log_debug "complete_multipart_upload"
        parts_resp = @client.list_parts(options)

        those_parts = parts_resp.parts.map do |part| 
          { part_number: part.part_number, etag: part.etag }
        end
        opts = options.merge({
          multipart_upload: {
            parts: those_parts
            } 
          })
        mpu_complete_response = @client.complete_multipart_upload(opts)
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