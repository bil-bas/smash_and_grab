module SmashAndGrab
  module Gui
    class EntityPanel < Fidgit::Horizontal
      event :info_toggled

      def initialize(entity, info_shown, options = {})
        options = {
            padding: 0,
            spacing: 8,
        }.merge! options

        super options

        @entity = entity
        @info_shown = info_shown

        vertical padding: 0 do
          # TODO: Clicking on portrait should center.
          @portrait = image_frame @entity.image, padding: 0, background_color: Color::GRAY
          @info_toggle = toggle_button "Bio", value: @info_shown, tip: "Show/hide biography",
                                       font_height: 14, align_h: :center do |_, value|
            @info_shown = value
            publish :info_toggled, value
            switch_sub_panel
          end
        end

        vertical padding: 0, spacing: 4 do
          @name = label @entity.name
          @sub_panel_container = vertical spacing: 0, padding: 0
        end

        create_details_sub_panel
        create_info_sub_panel
        switch_sub_panel
      end

      def switch_sub_panel
        @sub_panel_container.clear
        @sub_panel_container.add @info_shown ? @info_sub_panel : @details_sub_panel
      end

      def create_info_sub_panel
        @info_sub_panel = Fidgit::Vertical.new padding: 0, spacing: 0 do
          scroll_window width: 350, height: 72 do
            text_area text: "#{@entity.name} once ate a pomegranate, but it took all day and all night... " * 5,
                      background_color: Color::NONE, width: 330, font_height: 14
          end
        end
      end

      def skill_str(skill)
        "#{skill.capitalize} (#{'*' * @entity.ability(skill).skill})"
      end

      def create_details_sub_panel
        @details_sub_panel = Fidgit::Horizontal.new padding: 0, spacing: 0 do
          vertical padding: 0, spacing: 1, width: 160 do
            @health = label "", font_height: 20
            @movement_points = label "", font_height: 20
            @action_points = label "", font_height: 20
          end

          grid num_columns: 4, spacing: 4, padding: 0 do
            button_options = { font_height: 20, width: 28, height: 28, padding: 0, padding_left: 8 }

            @ability_buttons = {}

            tip = if @entity.has_ability? :melee
                    "#{skill_str :melee} attack in hand-to-hand combat"
                  else
                    "Melee [n/a]"
                  end
            @ability_buttons[:melee] = button "Me", button_options.merge(tip: tip)

            tip = if @entity.has_ability? :ranged
                    "#{skill_str :ranged} attack in ranged combat"
                  else
                    "Ranged [n/a]"
                  end
            @ability_buttons[:ranged] = button "Ra", button_options.merge(tip: tip)

            tip = if @entity.has_ability? :sprint
                    sprint = @entity.ability(:sprint)
                    "#{skill_str :sprint} gain #{sprint.movement_bonus} movement points at cost of all actions"
                  else
                    "Sprint [n/a]"
                  end
            @ability_buttons[:sprint] = button "Sp", button_options.merge(tip: tip) do
              @entity.use_ability :sprint
            end

            @ability_buttons[:a] = button "??", button_options.merge(tip: "???")

            @ability_buttons[:b] = button "P1", button_options.merge(tip: "power1")
            @ability_buttons[:c] = button "P2", button_options.merge(tip: "power2")
            @ability_buttons[:d] = button "P3", button_options.merge(tip: "power3")
            @ability_buttons[:e] = button "P4", button_options.merge(tip: "power4")
          end
        end
      end

      def update
        @health.text = "HP: #{@entity.health} / #{@entity.max_health}"
        @movement_points.text = "MP: #{@entity.mp} / #{@entity.max_mp}"
        @action_points.text = "AP: #{@entity.ap} / #{@entity.max_ap}"

        if @entity.has_ability? :sprint
          @movement_points.text += " +#{@entity.ability(:sprint).movement_bonus}"
        end

        @ability_buttons.each do |ability, button|
          button.enabled = (@entity.active? and (@entity.has_ability?(ability) and @entity.action_points >= @entity.ability(ability).action_cost))
        end

        super
      end
    end
  end
end