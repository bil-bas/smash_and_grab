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

    @box = horizontal padding: 0, spacing: 4 do
      @portrait = image_frame nil, background_color: Color::GRAY,
                              border_thickness: 1, border_color: Color::BLACK

      # Just to get a position to place the stats box.
      @stats_position = vertical padding: 0
    end

    self.entity = entity
  end

  def draw
    super
    @entity.draw_stat_bars x: @stats_position.x, y: @stats_position.y + 1, zorder: z, factor_x: 6, factor_y: 6

    if @entity.contents
      # TODO: Measure the sprite properly.
      @entity.contents.image.draw x + width - 10, y - 12, z
    end
  end

  public
  def update_details(entity)
    self.tip = "HP: #{entity.hp} / #{entity.max_hp}; MP: #{entity.mp} / #{entity.max_mp}; AP: #{entity.ap} / #{entity.max_ap}"

    @portrait.image = entity.portrait
    @name.color = entity.alive? ? Color::WHITE : Color::GRAY
    @portrait.enabled = entity.alive?
  end

  public
  def hit_element(x, y)
    hit?(x, y) ? self : nil
  end

  public
  def entity=(entity)
    @entity = entity

    @name.text = " " + @entity.name[0...13]
    @entity.subscribe :changed, &method(:update_details)

    update_details @entity

    entity
  end
end
end
end