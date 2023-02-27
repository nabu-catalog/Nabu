namespace :data do
  desc 'Check checksums for all files (one batch at a time)'
  task :check_all_checksums => :environment do
    dry_run = ENV['DRY_RUN'] ? true : false
    batch_size = ENV['BATCH_SIZE'] ? ENV['BATCH_SIZE'].to_i : 10

    ChecksumAnalyserService.check_in_batches(batch_size, dry_run)
  end
end
