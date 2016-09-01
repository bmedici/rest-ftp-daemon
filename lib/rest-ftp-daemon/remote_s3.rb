require 'aws-sdk-resources'

# Handle sFTP transfers for Remote class
module RestFtpDaemon
  class RemoteS3 < Remote

    # Class options
    attr_reader :client
    attr_reader :target

    def prepare
      log_debug "RemoteS3.prepare target[#{@target.inspect}]"
    end

    def connect
      super

      # Connect init
      log_debug "RemoteS3.connect region[#{target.aws_region}] id[#{target.aws_id}]"

      # Debug level
      verbosity =  @debug ? Logger::DEBUG : false

      # Connect remote server
      @client = Aws::S3::Resource.new(
        region: @target.aws_region,
        credentials: Aws::Credentials.new(@target.aws_id, @target.aws_secret)
        )
    end

    def upload source, target, use_temp_name = false, &callback
      # Push init
      raise RestFtpDaemon::AssertionFailed, "upload/client" if @client.nil?
      log_debug "RemoteS3.upload bucket[#{target.aws_bucket}] name[#{target.name}]"

      # Update progress before
      #yield 0, target.name

      # Do the transfer
      bucket = @client.bucket(target.aws_bucket)
      object = bucket.object(target.name)
      object.upload_file source.path do |progress, total|
        log_debug "- progress[#{progress}] total[#{total}]"
      end

      # Update progress after
      #yield target.size, target.name

      # Dump information about this file
      log_debug "RemoteS3.upload url[#{object.public_url}]"
      log_debug "RemoteS3.upload etag[#{object.etag}]"
      set_info :target, :aws_public_url, object.public_url
      set_info :target, :aws_etag, object.etag
    end

    def connected?
      !@client.nil?
    end

  end
end
