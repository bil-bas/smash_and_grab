class Fidgit::EntitySummary < Fidgit::Vertical
  BACKGROUND_COLOR = Color.rgb(0, 0, 150)

  def initialize(entity, options = {})
    options = {
      background_color: BACKGROUND_COLOR,
      padding_h: 0,
      padding_v: 0.5,
      spacing: 0.5,
      width: 30,
    }.merge! options

    super options

    @name = label "", font_height: 3

    horizontal padding: 0, spacing: 1 do
      @portrait = image_frame nil, factor: 0.25, padding: 0, background_color: Color::GRAY

      vertical padding: 0, spacing: 0 do
        @health = label "", font_height: 3
        @movement_points = label "", font_height: 3
        @action_points = label "", font_height: 3
      end
    end

     self.entity = entity
  end

  public
  def update
    self.entity = @entity if @entity
  end

  public
  def hit_element(x, y)
    self if hit?(x, y)
  end

  public
  def entity=(entity)
    @entity = entity

    @name.text = " " + entity.name[0...13]
    @health.text = "HP: #{@entity.health}"
    @movement_points.text = "MP: #{@entity.mp}"
    @action_points.text = "AP: #{@entity.ap}"
    @portrait.image = entity.image

    entity
  end
end