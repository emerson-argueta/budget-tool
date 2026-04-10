class CategoryGroup < ApplicationRecord
  has_many :budget_categories, dependent: :nullify

  validates :name, presence: true
  validates :position, presence: true

  scope :ordered, -> { order(:position) }

  DEFAULT_GROUPS = [
    { name: "Giving", position: 1 },
    { name: "Housing", position: 2 },
    { name: "Food", position: 3 },
    { name: "Transport", position: 4 },
    { name: "Personal", position: 5 },
    { name: "Debt", position: 6 },
    { name: "Savings", position: 7 },
    { name: "Other", position: 8 }
  ].freeze

  def self.seed_defaults!
    DEFAULT_GROUPS.each do |attrs|
      find_or_create_by!(name: attrs[:name]) { |g| g.position = attrs[:position] }
    end
  end
end
