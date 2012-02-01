require_relative "../../teststrap"

context Hash do
  setup { { "frog" => 12, "fish" => "hello", "cheese" => { "peas" => "knees" } } }
  asserts(:symbolize).equals(frog: 12, fish: :hello, cheese: { peas: :knees })
end