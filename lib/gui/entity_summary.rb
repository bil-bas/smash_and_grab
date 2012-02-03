module SmashAndGrab
module Gui
class EntitySummary < Fidgit::Vertical
  BACKGROUND_COLOR = Color.rgb(0, 0, 150)

  def initialize(entity, options = {})
    options = {
      background_color: BACKGROUND_COLOR,
      padding_h: 0,
      padding_v: 2,
      spacing: 2,
      width: 120,
    }.merge! options

    super options

    @name = label "", font_height: 15

    horizontal padding: 0, spacing: 4 do
      @portrait = image_frame nil, padding: 0, background_color: Color::GRAY,
                              border_thickness: 1, border_color: Color::BLACK

      vertical padding: 0, spacing: 0 do
        @health = label "", font_height: 15
        @movement_points = label "", font_height: 15
        @action_points = label "", font_height: 15
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
    hit?(x, y) ? self : nil
  end

  public
  def entity=(entity)
    @entity = entity

    @name.text = " " + entity.name[0...13]
    @health.text = "HP: #{@entity.health}"
    @movement_points.text = "MP: #{@entity.mp}"
    @action_points.text = "AP: #{@entity.ap}"
    @portrait.image = entity.portrait

    entity
  end
end
end
end