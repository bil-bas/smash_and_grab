module SmashAndGrab
module Gui
class InfoPanel < Fidgit::Vertical
  def initialize(options = {})
    options = {
        padding: 4,
        background_color: Color::BLACK,
    }.merge! options
    super options

    @frame = horizontal padding: 4, spacing: 8, background_color: Color.rgb(0, 0, 150), width: 440, height: 112 do
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

            @ability_buttons = {}
            @ability_buttons[:melee] = button "Me", button_options
            @ability_buttons[:ranged] = button "Ra", button_options
            @ability_buttons[:sprint] = button "Sp", button_options do
              @entity.map.actions.do :ability, @entity.ability(:sprint).action_data
            end

            @ability_buttons[:a] = button "??", button_options.merge(tip: "???")

            @ability_buttons[:b] = button "P1", button_options.merge(tip: "power1")
            @ability_buttons[:c] = button "P2", button_options.merge(tip: "power2")
            @ability_buttons[:d] = button "P3", button_options.merge(tip: "power3")
            @ability_buttons[:e] = button "P4", button_options.merge(tip: "power4")
          end
        end
      end
    end

    recalc

    self.x, self.y = ($window.width - width) / 2, $window.height - height
  end

  public
  def update
    return unless @entity

    @health.text = "HP: #{@entity.health} / #{@entity.max_health}"
    @movement_points.text = "MP: #{@entity.mp} / #{@entity.max_mp}"
    @action_points.text = "AP: #{@entity.ap} / #{@entity.max_ap}"

    if @entity.has_ability? :sprint
      @movement_points.text += " +#{@entity.ability(:sprint).movement_bonus}"
    end

    @ability_buttons.each do |ability, button|
      button.enabled = (@entity.has_ability?(ability) and @entity.action_points >= @entity.ability(ability).action_cost)
    end
  end

  public
  def entity=(entity)
    @entity = entity

    @frame.shown = (not entity.nil?)

    if entity
      @portrait.image = @entity.image
      @name.text = @entity.name

      if @entity.has_ability? :melee
        melee = @entity.ability(:melee)
        @ability_buttons[:melee].tip = "Melee[#{melee.skill}] - attack in hand-to-hand combat"
      else
        @ability_buttons[:melee].tip = "Melee[n/a)"
      end

      if @entity.has_ability? :ranged
        ranged = @entity.ability(:ranged)
        @ability_buttons[:ranged].tip = "Ranged[#{ranged.skill}] - attack in ranged combat"
      else
        @ability_buttons[:ranged].tip = "Ranged[n/a)"
      end

      if @entity.has_ability? :sprint
        sprint = @entity.ability(:sprint)
        @ability_buttons[:sprint].tip = "Sprint[#{sprint.skill}] - gain #{sprint.movement_bonus} movement points"
      else
        @ability_buttons[:sprint].tip = "Sprint[n/a]"
      end

      update
    end

    entity
  end
end
end
end
