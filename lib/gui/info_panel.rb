class InfoPanel < Fidgit::Vertical
  def initialize(options = {})
    options = {
        padding: 1,
        background_color: Color::BLACK,
    }.merge! options
    super options

    horizontal padding: 1, spacing: 2, background_color: Color.rgb(0, 0, 150), width: 110, height: 28 do
      @portrait = image_frame Entity.sprites[0, 0], factor: 0.25, padding: 0, background_color: Color::GRAY

      vertical padding: 0, spacing: 1 do
        @name = label " ", font_size: 6

        horizontal padding: 0, spacing: 0 do
          vertical padding: 0, spacing: 1, width: 40 do
            @health = label "", font_height: 4
            @movement_points = label "", font_height: 4
            @action_points = label "", font_height: 4
          end

          grid num_columns: 4, spacing: 1, padding: 0 do
            button_options = { font_height: 4, width: 7, height: 7, padding: 0, padding_left: 2 }

            button "M", button_options.merge(tip: "melee")
            button "R", button_options.merge(tip: "ranged")
            @sprint = button "S", button_options.merge(tip: "Sprint - gain (maximum MP / 2) movement points") do
              @entity.map.actions.do :sprint, @entity if @entity.sprint?
            end

            button "?", button_options.merge(tip: "???")

            button "P1", button_options.merge(tip: "power1")
            button "P2", button_options.merge(tip: "power2")
            button "P3", button_options.merge(tip: "power3")
            button "P4", button_options.merge(tip: "power4")
          end
        end
      end
    end

    recalc

    self.x, self.y = ($window.width / 4 - width) / 2, $window.height / 4 - height
  end

  public
  def update
    self.entity = @entity if @entity
  end

  public
  def entity=(entity)
    @entity = entity

    @portrait.image = @entity.image
    @name.text = @entity.name
    @health.text = "HP: #{@entity.health} / #{@entity.max_health}"
    @movement_points.text = "MP: #{@entity.mp} / #{@entity.max_mp}+#{entity.sprint_bonus}"
    @action_points.text = "AP: #{@entity.ap} / #{@entity.max_ap}"

    @sprint.enabled = @entity.sprint?

    entity
  end
end
