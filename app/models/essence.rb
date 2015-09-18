class Essence < ActiveRecord::Base
  include IdentifiableByDoi

  belongs_to :item

  validates :item, :associated => true
  validates :filename, :presence => true
  validates :mimetype, :presence => true
  validates :bitrate, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
  validates :samplerate, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}
  validates :size, :presence => true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :duration, :numericality => {:greater_than => 0, :allow_nil => true}
  validates :channels, :numericality => {:greater_than => 0, :allow_nil => true}
  validates :fps, :numericality => {:only_integer => true, :greater_than => 0, :allow_nil => true}

  attr_accessible :item, :item_id, :filename, :mimetype, :bitrate, :samplerate, :size, :duration, :channels, :fps

  def type
    types = mimetype.split("/",2)
    if types[1].nil?
      "unknown"
    else
      types[1].upcase
    end
  end

  def path
    Nabu::Application.config.archive_directory + "#{full_identifier}"
  end

  def full_identifier
    item.collection.identifier + '/' + item.identifier + '/' + filename
  end

  def next_essence
    Essence.where(:item_id => self.item).order(:id).where('id > ?', self.id).first
  end

  def prev_essence
    Essence.where(:item_id => self.item).order(:id).where('id < ?', self.id).last
  end

  def title
    filename
  end

  def full_path
    # TODO: probably want to change this to be filename at some point, non-urgent though
    "#{item.full_path}/essences/#{id}"
  end

  def collector_name
    item.collection.collector_name
  end

end
