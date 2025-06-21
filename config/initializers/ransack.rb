# config/initializers/ransack.rb

Ransack.configure do |config|
  # This tells Ransack how to interpret a custom predicate 'str'
  # When used as `_str_cont`, it will effectively cast the column to TEXT.
  # This is a common workaround for searching integer/numeric columns as strings.
  config.add_predicate 'str',
                       arel_attribute: proc { |v| Arel::Nodes::NamedFunction.new('CAST', [v.as('TEXT')]) },
                       formatter: proc { |v| "%#{v}%" },
                       validator: proc { |v| v.present? },
                       type: :string
end