shared Abilities::Ability do
  should "behave like an Abilities::Ability" do
    subject.should.be.kind_of Abilities::Ability
    [true, false].should.include subject.can_be_undone?
  end
end