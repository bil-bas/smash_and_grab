require_relative "../../teststrap"

context Hash do
  context "symbolising keys" do
    setup { { "x" => 12, "y" => 1 } }
    asserts(:symbolize).equals(x: 12, y: 1)
  end

  context "symbolising values" do
    setup { { "x" => "frog", "y" => "Frog", "z" => "cheese_pie2", "a" => "cheese pie" } }
    asserts(:symbolize).equals(x: :frog, y: "Frog", z: :cheese_pie2, a: "cheese pie")
  end

  context "symbolising array values" do
    setup { { "x" => ["y", { "z" => 2 }] } }
    asserts(:symbolize).equals(x: [:y, { z: 2 }])
  end

  context "symbolising nested hashes" do
    setup { { "x" => { "x" => 12, "y" => 1 } } }
    asserts(:symbolize).equals(x: { x: 12, y: 1 })
  end
end