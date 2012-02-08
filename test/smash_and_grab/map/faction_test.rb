require_relative "../../teststrap"

shared SmashAndGrab::Factions::Faction do
  should "not be active" do
    subject.should.not.be.active
  end

  should "have no entities" do
    subject.entities.should.be.kind_of Array
    subject.entities.should.be.empty
  end
end

describe SmashAndGrab::Factions::Faction do
  before do
    @baddies = SmashAndGrab::Factions::Baddies.new
    @goodies = SmashAndGrab::Factions::Goodies.new
    @bystanders =  SmashAndGrab::Factions::Bystanders.new
  end

  subject { described.new }

  describe SmashAndGrab::Factions::Goodies do
    behaves_like SmashAndGrab::Factions::Faction

    should "dislike baddies" do
      subject.should.be.enemy? @baddies
      subject.should.not.be.friend? @baddies
    end

    should "like bystanders" do
      subject.should.not.be.enemy? @bystanders
      subject.should.be.friend? @bystanders
    end
  end

  describe SmashAndGrab::Factions::Baddies do
    behaves_like SmashAndGrab::Factions::Faction

    should "dislike goodies" do
      subject.should.be.enemy? @goodies
      subject.should.not.be.friend? @goodies
    end

    should "dislike bystanders" do
      subject.should.be.enemy? @bystanders
      subject.should.not.be.friend? @bystanders
    end
  end

  describe SmashAndGrab::Factions::Bystanders do
    behaves_like SmashAndGrab::Factions::Faction

    should "like goodies" do
      subject.should.not.be.enemy? @goodies
      subject.should.be.friend? @goodies
    end

    should "dislike baddies" do
      subject.should.be.enemy? @baddies
      subject.should.not.be.friend? @baddies
    end
  end
end