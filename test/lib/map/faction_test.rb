require_relative "../../teststrap"

def standard_faction
  denies(:active?)
  asserts(:entities).empty
end

context Faction do
  setup do
    # These should be unique.
    @baddies = Faction::Baddies.new nil
    @goodies =  Faction::Goodies.new nil
    @bystanders = Faction::Bystanders.new nil
  end

  context Faction::Goodies do
    setup { @goodies }

    asserts("dislikes baddies") { topic.enemy? @baddies }
    denies("likes baddies") { topic.friend? @baddies }

    denies("dislikes bystanders") { topic.enemy? @bystanders }
    asserts("likes bystanders") { topic.friend? @bystanders }

    standard_faction
  end

  context Faction::Baddies do
    setup { @baddies }

    asserts("dislikes goodies") { topic.enemy? @goodies }
    denies("likes goodies") { topic.friend? @goodies }

    asserts("dislikes bystanders") { topic.enemy? @bystanders }
    denies("likes bystanders") { topic.friend? @bystanders }

    standard_faction
  end

  context Faction::Bystanders do
    setup { @bystanders }

    asserts("dislikes baddies") { topic.enemy? @baddies }
    denies("likes baddies") { topic.friend? @baddies }

    denies("dislikes goodies") { topic.enemy? @goodies }
    asserts("likes goodies") { topic.friend? @goodies }

    standard_faction
  end
end