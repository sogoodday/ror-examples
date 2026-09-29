module BenefitFocus
  class ProcessFileWorker < AsyncRunner
    unique!

    def run(_mode = nil)
      root = 'fake-root'
      sftp = SFTPService.new('fake-url', 'fake-username', 'fake-password')

      credentials = Aws::Credentials.new('fake-key-id', 'fake-access-key')
      s3_client   = Aws::S3::Client.new(region: 'fake-region', credentials: credentials)
      bucket      = Aws::S3::Resource.new(client: s3_client).bucket('fake-bucket')

      sftp
        .entries(root)
        .select { |item| item.name =~ /.?_[0-9]{14}\.xml.pgp/ }
        .sort { |a, b| a.name <=> b.name }
        .each do |file|
          next if @partner.partner_events.file_processed.where("params-> 'filename' = ?", file.name).any?

          encrypted = sftp.download([root, file.name].join('/'))
          bucket.object(file.name).put(body: encrypted)
          data = Ox.parse(decrypt(encrypted).to_s)
          BenefitFocusFileProcessor.process(data, file.name)
        end
    end

    private

    def decrypt(data)
      PGPService.new(private_key: 'fake-private-key').decrypt!(data)
    end
  end
end
