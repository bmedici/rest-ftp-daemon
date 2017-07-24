# Handle sFTP transfers for Remote class
module RestFtpDaemon::Remote
  class RemoteS3 < Base

      # Class options
      attr_reader :client
      attr_reader :target

      def initialize target, job, config
        super
      end

      def connect
        super

        # Connect remote server
        @client = Aws::S3::Client.new(
          region: @target.aws_region,
          credentials: Aws::Credentials.new(@target.aws_id, @target.aws_secret),
          http_wire_trace: debug_enabled
          )

      rescue Exception => exception
        raise RemoteConnectError, "#{exception.class}: #{exception.message}"
      end

      def size_if_exists target
        log_debug "size_if_exists rel[#{target.path_rel}]"
        object = @client.get_object(bucket: target.aws_bucket, key: target.path_rel)
      rescue Aws::S3::Errors::NotFound => e
        return false
      else
        return object.content_length
      end

      def push source, target, &callback
        # Push init
        raise RestFtpDaemon::AssertionFailed, "push/client" if @client.nil?

        # Do the transfer, passing the file to the best method
        File.open(source.path_abs, 'r', encoding: 'BINARY') do |file|
          if file.size >= JOB_S3_MIN_PART
            upload_multipart  file, target.aws_bucket, target.path_rel, target.name, &callback
          else
            upload_onefile    file, target.aws_bucket, target.path_rel, target.name, &callback
          end
        end
      end

      def move source, target
        # Identify the source object
        # obj = @client.bucket(source.aws_bucket).object(source.path_rel)
        # raise RestFtpDaemon::AssertionFailed, "move: object not found" unless obj

        # Move the file
        # log_debug "move: copy bucket[#{source.aws_bucket}] source[#{source.path_rel}] target[#{target.path_rel}]"
        @client.copy_object(bucket: source.aws_bucket, key: target.path_rel, copy_source: "#{source.aws_bucket}/#{source.path_rel}")
        # log_debug "move: delete bucket[#{source.aws_bucket}] source[#{source.path_rel}]"
        @client.delete_object(bucket: source.aws_bucket, key: source.path_rel)
        # log_debug "move: done"

        # Move the file
        # obj.move_to(target.path_rel, :bucket_name => target.aws_bucket)
      end

      def connected?
        !@client.nil?
      end

    private

      def upload_onefile file, s3_bucket, s3_path, s3_name, &callback
        log_debug "push: put_object", {
          s3_bucket:    s3_bucket,
          s3_path:      s3_path,
          }
        @client.put_object(bucket: s3_bucket, key: s3_path, body: file)
      end

      def upload_multipart file, s3_bucket, s3_path, s3_name, &callback
        # Init
        current_part  = 1

        # Compute parameters
        file_size     = file.size
        parts_size    = compute_parts_size(file_size)
        parts_count   = (file_size.to_f / parts_size).ceil

        # Prepare basic opts
        options = {
          bucket: s3_bucket,
          key:    s3_path,
          }

        # Declare multipart upload
        mpu_create_response = @client.create_multipart_upload(options)
        options[:upload_id] = mpu_create_response.upload_id
        log_debug "push: create_multipart_upload", {
          s3_bucket:    s3_bucket,
          s3_path:      s3_path,
          upload_id:    options[:upload_id],
          file_size:    format_bytes(file_size, "B"),
          parts_size:   format_bytes(parts_size, "B"),
          parts_count:  parts_count
          }

        # Upload each part
        file.each_part(parts_size) do |part|
          # Prepare part upload
          opts = options.merge({
            body:        part,
            part_number: current_part,
            })
          part_size = part.bytesize
          log_debug "upload_part [#{current_part}/#{parts_count}] part_size[#{part_size}]"

          # Push this over there
          resp = @client.upload_part(opts)
          
          # Send progress info upwards
          yield part_size, s3_name

          # Increment part number
          current_part += 1
        end

        # Retrieve parts and complete upload
        parts_resp = @client.list_parts(options)
        those_parts = parts_resp.parts.map do |part| 
          { part_number: part.part_number, etag: part.etag }
        end
        opts = options.merge({
          multipart_upload: {
            parts: those_parts
            } 
          })
        log_debug "complete_multipart_upload"
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

      def debug_enabled
        @config[:debug_s3]
      end

  end
end