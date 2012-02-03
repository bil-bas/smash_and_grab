require_relative "../../teststrap"

describe Hash do
  should "symbolise keys" do
    { "x" => 12, "y" => 1 }.symbolize.should.equal(x: 12, y: 1)
  end

  should "symbolise values" do
    { "x" => "frog", "y" => "Frog", "z" => "cheese_pie2", "a" => "cheese pie" }.symbolize.should.equal(
        x: :frog, y: "Frog", z: :cheese_pie2, a: "cheese pie"
    )
  end

  should "symbolise array values" do
    { "x" => ["y", { "z" => 2 }] }.symbolize.should.equal(x: [:y, { z: 2 }])
  end

  should "symbolise nested hashes" do
    { "x" => { "x" => 12, "y" => 1 } }.symbolize.should.equal(x: { x: 12, y: 1 })
  end
end