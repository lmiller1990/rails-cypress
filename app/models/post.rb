class Post < ApplicationRecord
  validates :title, { length: { minimum: 5 } } 
  belongs_to :category
end
