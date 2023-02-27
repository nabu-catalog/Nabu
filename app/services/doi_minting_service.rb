require 'uri'
require 'net/http'

class DoiMintingService

  def initialize(dry_run)
    @base_url = ENV['DATACITE_BASE_URL']
    @prefix = ENV['DOI_PREFIX']
    @user = ENV['DATACITE_USER']
    @pass = ENV['DATACITE_PASS']
    @dry_run = dry_run
  end

  def mint_doi(doiable)
    if @dry_run
      puts "DRY_RUN: DOI minting for #{doiable.id}"

      return true
    end

    response = post_to_mds :metadata, doiable.to_doi_xml

    if response.code == "201"
      doi = response.body[/\AOK \(([^\)]+)\)\z/, 1]
      uri = URI.parse url_for(:doi)

      response = post_to_mds :doi, "doi=#{doi}\nurl=#{doiable.full_path}"
      if response.code == "201"
        puts ("DOI #{doi} minted for #{doiable.full_path}")
        doiable.doi = doi
        doiable.save
      end
    else
      puts ("DOI minting failed for #{doiable.full_path}")
      false
    end
  end

  private

  def url_for(action)
    if %i(metadata doi).include? action
      "#{@base_url}/#{action}/#{@prefix}"
    end
  end

  def content_type_for(action)
    case action
    when :metadata
      "application/xml;charset=UTF-8"
    when :doi
      "text/plain;charset=UTF-8"
    end
  end

  def post_to_mds(action, body)
    uri = URI.parse url_for(action)
    connection = Net::HTTP.new uri.host, uri.port
    connection.use_ssl = true

    request = Net::HTTP::Put.new uri.request_uri
    request['Content-Type'] = content_type_for(action)
    request.basic_auth @user, @pass
    request.body = body
    connection.request(request)
  end
end
