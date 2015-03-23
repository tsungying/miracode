class Product < ActiveRecord::Base
  belongs_to :prod_category, counter_cache: true
  before_save :downcase_part_number
  validates_presence_of :name, :part_number, :original_price, :selling_price, :brief#, :description
  validates :part_number, uniqueness: { case_sensitive: false }
  #attr_accessible :brief, :description, :name, :original_price, :part_number, :selling_price
  
  private
  	def downcase_part_number
  		self.part_number = self.part_number.downcase
  	end
end
