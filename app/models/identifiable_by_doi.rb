module IdentifiableByDoi
  def to_doi_xml
    xml = ::Builder::XmlMarkup.new
    xml.tag! 'resource', schema_definitions do
      xml.tag! 'creators' do
        xml.tag! 'creator' do
          xml.tag! 'creatorName', collector_name
        end
      end
      xml.tag! 'identifier', '10.4225/72/bcndhj78437hjk', identifierType: 'DOI'
      xml.tag! 'titles' do
        xml.tag! 'title', title
      end
      xml.tag! 'publisher', 'PARADISEC'
      # Items are the only type which contain the true publication date, so prefer that, but fall back to the date it was added to Nabu
      publicationYear = case
                        when is_a?(Item)
                          originated_on || created_at
                        when is_a?(Essence)
                          item.originated_on || created_at
                        else
                          created_at
                        end.year

      xml.tag! 'publicationYear', publicationYear

      xml.tag! 'contributors' do
        xml.tag! 'contributor', contributorType: 'DataCollector' do
          xml.tag! 'contributorName', collector_name
        end

        if respond_to?(:university_name) && university_name.present?
          xml.tag! 'contributor', contributorType: 'DataCollector' do
            xml.tag! 'contributorName', university_name
          end
        end
      end

      # parent should exist for everything except Collection
      if parent.present?
        xml.tag! 'relatedIdentifiers' do
          xml.tag! 'relatedIdentifier', parent.doi, relatedIdentifierType: 'DOI', relationType: is_a?(Item) ? 'IsPartOf' : 'IsSourceOf'
        end
      end
    end
  end

  private

  def schema_definitions
    {
      'xmlns' => 'http://datacite.org/schema/kernel-3',
      'xsi:schemaLocation' => 'http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
    }
  end
end
