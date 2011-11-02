class Faction
  extend Forwardable

  # Super-villains
  class Baddies < self
    COLOR = Color.rgb(255, 50, 50)
  end

  # Superheroes, police, g-men, etc.
  class Goodies < self
    COLOR = Color.rgb(100, 100, 255)
    def friend?(faction); (faction.is_a? Bystanders) or super; end
  end

  # Everyone else (NPCS).
  class Bystanders < self
    COLOR = Color.rgb(255, 255, 0)

    def friend?(faction); (faction.is_a? Goodies) or super; end
  end

  # -----------------------------------------------

  def_delegators :@entities, :[]

  def friend?(faction); faction.is_a? self.class; end
  def enemy?(faction); not friend?(faction); end
  def to_s; Inflector.demodulize self.class.name; end
  def minimap_color; self.class::COLOR; end

  def initialize
    @entities = []
  end

  def <<(entity)
    @entities << entity
  end

  def remove(entity)
    @entities.delete entity
  end
end
