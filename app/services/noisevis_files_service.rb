# Service to implement the archive:noisevis_files task
class NoisevisFilesService
  def self.run(archive, verbose)
    noisevis_files_service = new(archive, verbose)
    noisevis_files_service.run
  end

  def initialize(archive, verbose, dry_run)
    @archive = archive
    @verbose = verbose
    @dry_run = dry_run
  end

  def run
    # get all subdirectories in archive
    puts "---------------------------------------------------------------"
    puts "Gathering all subdirectories in the archive..."
    subdirs = directories(@archive)
    puts "...done"

    # extract metadata from each essence file in each directory
    subdirs.each do |directory|
      puts "===" if @verbose
      puts "---------------------------------------------------------------" if @verbose
      puts "Working through directory #{directory}" if @verbose
      dir_contents = Dir.entries(directory)
      dir_contents.each do |file|
        next unless File.file? "#{directory}/#{file}"
        puts "---------------------------------------------------------------" if @verbose
        puts "Inspecting file #{file}..."
        # REVIEW: wav or mp3?
        basename, _extension, _coll_id, _item_id, collection, item = parse_file_name(file, "mp3")
        unless collection && item
          # No need to log a failure message, as parse_file_name does that.
          next
        end

        spectrum_filename = basename + "-spectrum-PDSC_ADMIN.jpg"
        json_filename = basename + "-spectrum-PDSC_ADMIN.json"

        if File.exist?("#{directory}/#{spectrum_filename}") && File.exist?("#{directory}/#{json_filename}")
          next
        end

        begin
          if @dry_run
            puts "DRY_RUN: Would run noisevis on #{file}"
            result = true
          else
            result = system("noisevis -json true -i #{directory}/#{file} -o #{directory}/#{spectrum_filename}")
          end
        rescue
          puts "ERROR: unable to process file #{file} - skipping"
          next
        end

        unless result
          puts "ERROR: unable to process file #{file} - skipping"
          next
        end

        # Need to change json filename
        begin
          if @dry_run
            puts "DRY_RUN: would rename #{directory}/#{spectrum_filename}.json to #{directory}/#{json_filename}"
          else
            FileUtils.mv("#{directory}/#{spectrum_filename}.json", "#{directory}/#{json_filename}")
          end
        rescue
          puts "ERROR: file #{file} skipped - not able to rename JSON file" if @verbose
          next
        end

        puts "Created #{spectrum_filename} and #{json_filename}"
        # Sleep for 2 seconds, to ensure that this rake task isn't using the entirety of one of the two CPUs available
        sleep 2
      end
    end
    puts "===" if @verbose
    puts "Update Files finished." if @verbose
    puts "===" if @verbose
  end
end
