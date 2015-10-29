require 'media'
include ActionView::Helpers::NumberHelper

require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper


class OfflineTemplate < AbstractController::Base
  include AbstractController::Rendering
  include AbstractController::Helpers
  #include AbstractController::Layouts
  include CanCan::ControllerAdditions

  def initialize(*args)
    super()
    lookup_context.view_paths = Rails.root.join('app', 'views')
  end

  def current_user
    @current_user ||= User.admins.first
  end

  #def params
  #  {}
  #end
end

class ItemOfflineTemplate < OfflineTemplate
  attr_accessor :item
end

namespace :archive do

  desc 'Provide essence files in scan_directory with metadata for sealing'
  task :export_metadata => :environment do
    verbose = ENV['VERBOSE'] ? true : false

    # scan for WAV files .wav and create .imp.xml & id3.xml
    dir_contents = Dir.entries(Nabu::Application.config.scan_directory)

    # for each essence file, find its collection & item
    # by matching the pattern
    # "#{collection_id}-#{item_id}-xxx.xxx"
    dir_contents.each do |file|
      next unless File.file? "#{Nabu::Application.config.scan_directory}/#{file}"
      basename, _, coll_id, item_id, collection, item = parse_file_name(file, 'wav')
      next if !collection || !item

      # if metadata files exist, skip to the next file
      metadata_filename_imp = Nabu::Application.config.write_imp + basename + ".imp.xml"
      metadata_filename_id3 = Nabu::Application.config.write_id3 + basename + ".id3.v2_3.xml"
      next if (File.file? "#{metadata_filename_imp}") && (File.file? "#{metadata_filename_id3}")

      # check if the item's "metadata ready for export" flag is set
      # raise a warning if not and skip file
      if !item.metadata_exportable
        puts "ERROR: metadata of item pid=#{coll_id}-#{item_id} is not complete for file #{file} - skipping" if verbose
        next
      end

      template = ItemOfflineTemplate.new
      template.item = item
      data_imp = template.render_to_string :template => "items/show.imp.xml"
      data_id3 = template.render_to_string :template => "items/show.id3.xml"

      File.open(metadata_filename_imp, 'w') {|f| f.write(data_imp)}
      File.open(metadata_filename_id3, 'w') {|f| f.write(data_id3)}
      puts "SUCCESS: metadata files\n #{metadata_filename_imp},\n #{metadata_filename_id3}\n created for #{file}"
    end
  end


  desc 'Import files into the archive'
  task :import_files => :environment do
    verbose = ENV['VERBOSE'] ? true : false
    # Always update metadata, unlike the update_files task
    force_update = true

    # find essence files in Nabu::Application.config.upload_directories
    dir_list = Nabu::Application.config.upload_directories

    dir_list.each do |upload_directory|
      next unless File.directory?(upload_directory)
      dir_contents = Dir.entries(upload_directory)

      # for each essence file, find its collection & item
      # by matching the pattern
      # "#{collection_id}-#{item_id}-xxx.xxx"
      dir_contents.each do |file|
        next unless File.file? "#{upload_directory}/#{file}"

        # skip files of size 0 bytes
        unless File.size?("#{upload_directory}/#{file}")
          puts "WARNING: file #{file} skipped, since it is empty" if verbose
          next
        end

        # skip files that can't be read
        unless File.readable?("#{upload_directory}/#{file}")
          puts "ERROR: file #{file} skipped, since it's not readable" if verbose
          next
        end

        # Skip files that are currently uploading
        last_updated = File.stat("#{upload_directory}/#{file}").mtime
        if (Time.now - last_updated) < 60*10
          next
        end

        basename, extension, coll_id, item_id, collection, item = parse_file_name(file)
        next unless (collection && item)

        # skip files with item_id longer than 30 chars, because OLAC can't deal with them
        if item_id.length > 30
          puts "WARNING: file #{file} skipped - item id longer than 30 chars (OLAC incompatible)" if verbose
          next
        end

        puts '---------------------------------------------------------------'

        # make sure the archive directory for the collection and item exists
        # and move the file there
        begin
          destination_path = Nabu::Application.config.archive_directory + "#{coll_id}/#{item_id}/"
          FileUtils.mkdir_p(destination_path)
        rescue
          puts "WARNING: file #{file} skipped - not able to create directory #{destination_path}" if verbose
          next
        end

        begin
          FileUtils.cp(upload_directory + file, destination_path + file)
        rescue
          puts "WARNING: file #{file} skipped - not able to read it or write to #{destination_path + file}" if verbose
          next
        end

        puts "SUCCESS: file #{file} copied into archive at #{destination_path}"

        # move old style CAT and df files to the new naming scheme
        if basename.split('-').last == "CAT" || basename.split('-').last == "df"
          FileUtils.mv(destination_path + file, destination_path + "/" + basename + "-PDSC_ADMIN." + extension)
        end

        # files of the pattern "#{collection_id}-#{item_id}-xxx-PDSC_ADMIN.xxx"
        # will be copied, but not added to the list of imported files in Nabu.
        if basename.split('-').last != "PDSC_ADMIN"
          # extract media metadata from file
          puts "Inspecting file #{file}..."
          begin
            import_metadata(destination_path, file, item, extension, force_update)
          rescue => e
            puts "WARNING: file #{file} skipped - error importing metadata [#{e.message}]" if verbose
            puts " >> #{e.backtrace}"
            next
          end
        end

        # if everything went well, remove file from original directory
        FileUtils.rm(upload_directory + file)
        puts "...done"
      end
    end
  end

  desc 'Update essence metadata of existing files in the archive'
  task :update_files => :environment do
    verbose = ENV['VERBOSE'] ? true : false
    # Default to not forcing an update of metadata
    force_update = (ENV['FORCE'] == 'true')

    # find essence files in Nabu::Application.config.archive_directory
    archive = Nabu::Application.config.archive_directory

    # get all subdirectories in archive
    puts "---------------------------------------------------------------"
    puts "Gathering all subdirectories in the archive..."
    subdirs = directories(archive)
    puts "...done"

    # extract metadata from each essence file in each directory
    subdirs.each do |directory|
      puts "===" if verbose
      puts "---------------------------------------------------------------" if verbose
      puts "Working through directory #{directory}" if verbose
      dir_contents = Dir.entries(directory)
      dir_contents.each do |file|
        next unless File.file? "#{directory}/#{file}"
        puts "---------------------------------------------------------------" if verbose
        puts "Inspecting file #{file}..."
        basename, extension, coll_id, item_id, collection, item = parse_file_name(file)
        unless collection && item
          puts "ERROR: skipping file #{file} - does not relate to an item #{coll_id}-#{item_id}"
          next
        end

        # skip PDSC_ADMIN and rename CAT & df files
        next if basename.split('-').last == "PDSC_ADMIN"
        if basename.split('-').last == "CAT" || basename.split('-').last == "df"
          FileUtils.mv(directory + "/" + file, directory + "/" + basename + "-PDSC_ADMIN." + extension)
          next
        end

        # extract media metadata from file
        import_metadata(directory, file, item, extension, force_update)
      end
    end
    puts "===" if verbose
    puts "Update Files finished." if verbose
    puts "===" if verbose
  end


  desc 'Create all missing PDSC_ADMIN files'
  task :admin_files => :environment do
    verbose = ENV['VERBOSE'] ? true : false

    # find essence files in Nabu::Application.config.archive_directory
    archive = Nabu::Application.config.archive_directory

    # get all subdirectories in archive
    puts "---------------------------------------------------------------"
    puts "Gathering all subdirectories in the archive..."
    subdirs = directories(archive)
    puts "...done"

    # extract metadata from each essence file in each directory
    subdirs.each do |directory|
      puts "===" if verbose
      puts "---------------------------------------------------------------" if verbose
      puts "Working through directory #{directory}" if verbose

      path, item_id = File.split(directory)
      path, coll_id = File.split(path)

      puts "item #{coll_id}-#{item_id}"
      # force case sensitivity in MySQL - see https://dev.mysql.com/doc/refman/5.7/en/case-sensitivity.html
      collection = Collection.where('BINARY identifier = ?', coll_id).first
      next unless collection
      item = collection.items.where('BINARY identifier = ?', item_id).first
      next unless item

      file = directory + "/#{item.full_identifier}-CAT-PDSC_ADMIN.xml"

      next if File.exists?(file)

      template = ItemOfflineTemplate.new
      template.item = item
      data = template.render_to_string :template => "items/show.xml.haml"
      File.open(file, 'w') {|f| f.write(data)}
      puts "created #{file}"
    end
    puts "===" if verbose
    puts "Check and create PDSC_ADMIN Files finished." if verbose
    puts "===" if verbose
  end

  desc 'Delete collection with all items'
  task :delete_collection, [:coll_id] => :environment do |t, args|
    coll_id = args[:coll_id]
    # force case sensitivity in MySQL - see https://dev.mysql.com/doc/refman/5.7/en/case-sensitivity.html
    collection = Collection.where('BINARY identifier = ?', coll_id).first
    unless collection
      abort("ERROR: no such collection #{coll_id}")
    end
    items = collection.items.size
    print "Do you really want to delete collection #{coll_id} with all its #{items} items? (y/n) "
    input = STDIN.gets.strip
    if input != 'y'
      abort("...aborted collection deletion.")
    end
    collection.items.each do |item|
      puts "Deleting item #{item.collection.identifier}-#{item.identifier}"
      item.destroy
    end
    # reload collection so it loses its now deleted item links
    # force case sensitivity in MySQL - see https://dev.mysql.com/doc/refman/5.7/en/case-sensitivity.html
    collection = Collection.where('BINARY identifier = ?', coll_id).first
    puts "Deleting collection #{collection.identifier}"
    collection.destroy
    puts "...done"

    # now check files in directory
    archive = Nabu::Application.config.archive_directory

    files = Dir.glob(archive + "#{coll_id}/*")
    if files.length > 0
      puts "\nNOW PLEASE REMOVE ARCHIVE FILES AND FOLDERS FOR COLLECTION #{coll_id}:"
      puts files
    end
  end

  desc "Mint DOIs for objects that don't have one"
  task :mint_dois => :environment do
    batch_size = Integer(ENV['MINT_DOIS_BATCH_SIZE'])
    BatchDoiMintingService.run(batch_size)
  end

  # HELPERS

  def directories(path)
    data = []
    Dir.foreach(path) do |entry|
      next if (entry == '..' || entry == '.' || entry == '.snapshot' || entry == '.server_backups')
      full_path = File.join(path, entry)
      if File.directory?(full_path)
        data << full_path
        data += directories(full_path)
      end
    end
    return data
  end


  def parse_file_name(file, file_extension=nil)
    verbose = ENV['VERBOSE'] ? true : false

    extension = file.split('.').last
    return if file_extension && file_extension != extension
    basename = File.basename(file, "." + extension)

    #use basename to avoid having item_id contain the extension
    coll_id, item_id = basename.split('-')
    return unless item_id

    # force case sensitivity in MySQL - see https://dev.mysql.com/doc/refman/5.7/en/case-sensitivity.html
    collection = Collection.where('BINARY identifier = ?', coll_id).first
    unless collection
      puts "ERROR: could not find collection id=#{coll_id} for file #{file} - skipping" if verbose
      return [basename, extension, coll_id, item_id, nil, nil]
    end

    # force case sensitivity in MySQL - see https://dev.mysql.com/doc/refman/5.7/en/case-sensitivity.html
    item = collection.items.where('BINARY identifier = ?', item_id).first
    unless item
      puts "ERROR: could not find item pid=#{coll_id}-#{item_id} for file #{file} - skipping" if verbose
      return [basename, extension, coll_id, item_id, nil, nil]
    end
    [basename, extension, coll_id, item_id, collection, item]
  end


  def import_metadata(path, file, item, extension, force_update)
    # since everything operates off of the full path, construct it here
    full_file_path = path + "/" + file

    # extract media metadata from file
    media = Nabu::Media.new full_file_path
    unless media
      puts "ERROR: was not able to parse #{full_file_path} of type #{extension} - skipping"
      return
    end

    # find essence file in Nabu DB; if there is none, create a new one
    essence = Essence.where(:item_id => item, :filename => file).first
    unless essence
      essence = Essence.new(:item => item, :filename => file)
    end

    generated_successfully = generate_derived_files(full_file_path, item, extension, media)
    return unless generated_successfully

      # update essence entry with metadata from file
    begin
      essence.mimetype   = media.mimetype
      essence.size       = media.size
      essence.bitrate    = media.bitrate
      essence.samplerate = media.samplerate
      essence.duration   = number_with_precision(media.duration, :precision => 3)
      essence.channels   = media.channels
      essence.fps        = media.fps
    rescue => e
      puts "ERROR: unable to process file #{file} - skipping"
      puts" #{e}"
      return
    end

    unless essence.valid?
      puts "ERROR: invalid metadata for #{file} of type #{extension} - skipping"
      essence.errors.each { |field, msg| puts "#{field}: #{msg}" }
      return
    end
    if essence.new_record? || (essence.changed? && force_update)
      essence.save!
      puts "SUCCESS: file #{file} metadata imported into Nabu"
    end
    if essence.changed? && !force_update
      puts "WARNING: file #{file} metadata is different to DB - use 'FORCE=true archive:update_file' to update"
      puts essence.changes.inspect
    end
  end


  # this method tries to avoid regenerating any files that already exist
  def generate_derived_files(full_file_path, item, extension, media)
    generated_essences = []

    if media.mimetype.start_with?('image')
      transformer = ImageTransformerService.new(media, full_file_path)

      # if the file is a tif, convert it to jpeg
      if media.mimetype == 'image/tiff'
        puts "Generate JPG#{transformer.multipart ? 's' : ''}"
        converted = transformer.convert_to :jpg, extension

        converted.each do |out|
          next if out.nil? # if files already existed, there will be nils instead of filenames
          generated_essences << Essence.new(item: item, filename: File.basename(out), mimetype: 'image/jpeg', size: File.size(out))
        end

        if transformer.multipart
          puts 'Generate PDF collection for pages'

          #if the input is multipart, also produce a pdf version of the whole thing
          multipart_file = transformer.convert_to :pdf, extension
          if multipart_file.present? # if the file didn't already exist
            generated_essences << Essence.new(item: item, filename: File.basename(multipart_file), mimetype: 'application/pdf',
                                              size: File.size(multipart_file))
          end
        end
      end

      #by default, this just generates a single thumbnail, but you can specify a comma-sep list of sizes
      # e.g. rake archive:import_files thumbnail_sizes='144,288,999'
      puts "Generate thumbnails#{transformer.multipart ? 's' : ''}"
      if ENV['thumbnail_sizes']
        transformer.generate_thumbnails extension, ENV['thumbnail_sizes'].split(',').map(&:strip)
      else
        transformer.generate_thumbnails extension
      end
    end

    generated_essences.each do |generated|
      if generated.valid?
        generated.save!
      else
        puts "ERROR: invalid metadata for #{file} of type #{extension} - skipping"
        generated.errors.each {|field, msg| puts "#{field}: #{msg}"}
        return false
      end
    end

    return true
  end
end
