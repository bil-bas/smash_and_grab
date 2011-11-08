class InfoPanel < Fidgit::Vertical
  def initialize(options = {})
    options = {
        padding: 1,
        background_color: Color::BLACK,
    }.merge! options
    super options

    horizontal padding: 1, spacing: 2, background_color: Color.rgb(0, 0, 150), width: 110, height: 25 do
      @portrait = image_frame Entity.sprites[0, 0], factor: 0.25, padding: 0, background_color: Color::GRAY

      vertical padding: 0, spacing: 1 do
        @name = label "", font_size: 6
        @health = label "", font_height: 4
        @movement_points = label "", font_height: 4
        @action_points = label "", font_height: 4
      end
    end

    recalc

    self.x, self.y = ($window.width / 4 - width) / 2, $window.height / 4 - height
  end

  public
  def entity=(entity)
    @entity = entity

    @portrait.image = @entity.image
    @name.text = @entity.name
    @health.text = "HP: #{@entity.health} / #{@entity.max_health}"
    @movement_points.text = "MP: #{@entity.mp} / #{@entity.max_mp}"
    @action_points.text = "AP: #{@entity.ap} / #{@entity.max_ap}"

    # TODO: get updates on changes to the entity's status.

    entity
  end
end
