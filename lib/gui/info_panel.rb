module SmashAndGrab
module Gui
class InfoPanel < Fidgit::Vertical
  def initialize(options = {})
    options = {
        padding: 4,
        background_color: Color::BLACK,
    }.merge! options
    super options

    horizontal padding: 4, spacing: 8, background_color: Color.rgb(0, 0, 150), width: 440, height: 112 do
      @portrait = image_frame Objects::Entity.sprites[0, 0], padding: 0, background_color: Color::GRAY

      vertical padding: 0, spacing: 4 do
        @name = label " "

        horizontal padding: 0, spacing: 0 do
          vertical padding: 0, spacing: 1, width: 160 do
            @health = label "", font_height: 20
            @movement_points = label "", font_height: 20
            @action_points = label "", font_height: 20
          end

          grid num_columns: 4, spacing: 4, padding: 0 do
            button_options = { font_height: 20, width: 28, height: 28, padding: 0, padding_left: 8 }

            button "Me", button_options.merge(tip: "Melee")
            button "Ra", button_options.merge(tip: "Ranged")
            @sprint = button "Sp", button_options.merge(tip: "Sprint - gain (maximum MP / 2) movement points") do
              @entity.map.actions.do :sprint, @entity if @entity.sprint?
            end

            button "??", button_options.merge(tip: "???")

            button "P1", button_options.merge(tip: "power1")
            button "P2", button_options.merge(tip: "power2")
            button "P3", button_options.merge(tip: "power3")
            button "P4", button_options.merge(tip: "power4")
          end
        end
      end
    end

    recalc

    self.x, self.y = ($window.width - width) / 2, $window.height - height
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
    @movement_points.text = "MP: #{@entity.mp} / #{@entity.max_mp}"
    @action_points.text = "AP: #{@entity.ap} / #{@entity.max_ap}"

    entity
  end
end
end
end
