# Batch minting of DOIs.
# For an individual minting, see DoiMintingService.
class BatchDoiMintingService
  def self.run(batch_size)
    batch_doi_minting_service = new(batch_size)
    batch_doi_minting_service.run
  end

  def initialize(batch_size)
    @batch_size = batch_size
    @doi_minting_service = create_doi_minting_service
    @unminted_objects = find_unminted_objects
  end

  def create_doi_minting_service
    DoiMintingService.new('json')
  end

  def find_unminted_objects
    Collection.where(doi: nil).limit(@batch_size)
  end

  def run
    @unminted_objects.each do |unminted_object|
      @doi_minting_service.mint_doi(unminted_object)
    end
  end
end
