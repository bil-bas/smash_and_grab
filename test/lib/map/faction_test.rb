require_relative "../../teststrap"

shared Factions::Faction do
  should "not be active" do
    subject.should.not.be.active
  end

  should "have no entities" do
    subject.entities.should.be.kind_of Array
    subject.entities.should.be.empty
  end
end

describe Factions::Faction do
  helper(:baddies) { Factions::Baddies.new nil }
  helper(:goodies) { Factions::Goodies.new nil }
  helper(:bystanders) { Factions::Bystanders.new nil }

  subject { described.new nil }

  describe Factions::Goodies do
    behaves_like Factions::Faction

    should "dislike baddies" do
      subject.should.be.enemy? baddies
      subject.should.not.be.friend? baddies
    end

    should "like bystanders" do
      subject.should.not.be.enemy? bystanders
      subject.should.be.friend? bystanders
    end
  end

  describe Factions::Baddies do
    behaves_like Factions::Faction

    should "dislike goodies" do
      subject.should.be.enemy? goodies
      subject.should.not.be.friend? goodies
    end

    should "dislike bystanders" do
      subject.should.be.enemy? bystanders
      subject.should.not.be.friend? bystanders
    end
  end

  describe Factions::Bystanders do
    behaves_like Factions::Faction

    should "like goodies" do
      subject.should.not.be.enemy? goodies
      subject.should.be.friend? goodies
    end

    should "dislike baddies" do
      subject.should.be.enemy? baddies
      subject.should.not.be.friend? baddies
    end
  end
end