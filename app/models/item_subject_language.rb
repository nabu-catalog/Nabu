# == Schema Information
#
# Table name: item_subject_languages
#
#  id          :integer          not null, primary key
#  item_id     :integer          not null
#  language_id :integer          not null
#

class ItemSubjectLanguage < ActiveRecord::Base
  has_paper_trail

  belongs_to :language
  belongs_to :item

  attr_accessible :language_id, :language, :item_id, :item

  validates :language_id, :presence => true
  #validates :item_id, :presence => true
end
