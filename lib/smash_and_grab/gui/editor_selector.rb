module SmashAndGrab
module Gui
class EditorSelector < Fidgit::Vertical
  OBJECT_TYPES = {
      tiles: {
          type: Tile,
          num_columns: 2,
          factor: 2,
      },
      walls: {
          type: Wall,
          num_columns: 3,
          factor: 1,
      },
      objects: {
          type: Objects::Static,
          num_columns: 2,
          factor: 1,
      },
      entities: {
          type: Objects::Entity,
          num_columns: 2,
          factor: 1,
      },
      vehicles: {
          type: Objects::Vehicle,
          num_columns: 1,
          factor: 0.5,
      },
  }

  OBJECT_TABS = OBJECT_TYPES.keys

  def tab; @tabs_group.value; end
  def tab=(tab); @tabs_group.value = tab; end
  def selected; @selector_group.value ;end

  def initialize(options = {})
    options = {
        padding: 4,
        background_color: Color::BLACK,
    }.merge! options

    super options

    vertical padding: 0, spacing: 0 do
      @tabs_group = group do
        @tab_buttons = horizontal padding: 0, spacing: 4 do
          OBJECT_TABS.each do |name|
            radio_button(name.to_s[0].capitalize, name, border_thickness: 0, padding: 8, tip: name.to_s.capitalize)
          end
        end

        subscribe :changed do |sender, value|
          current = @tab_buttons.find {|elem| elem.value == value }
          @tab_buttons.each {|t| t.enabled = (t != current) }
          current.color, current.background_color = current.background_color, current.color

          @tab_contents.clear

          scroll_options = { width: 200, height: 540 }

          @tab_windows[value] ||= Fidgit::ScrollWindow.new scroll_options do
            list_window value
          end

          @selector_window = @tab_windows[value]
          @tab_contents.add @selector_window
          @selector_group = @selector_window.content[0]
        end
      end

      @tab_contents = vertical padding: 0 do
         # Put the tab contents in here at a later date.
      end
    end

    @tab_windows = {} # Scrolling windows to put inside tab_contents. Created when tabbed to.

    self.tab = OBJECT_TABS.first
  end

  public
  # Pick up whatever is in a specific tile (triggered by right-click on map).
  def pick_up(tile, wall)
    case tab
      when :tiles
        @selector_group.value = tile.type if tile

      when :entities, :objects, :vehicles
        if tile
          object = tile.object
          if object
            self.tab = case object
                         when Objects::Entity then :entities
                         when Objects::Static then :objects
                         when Objects::Vehicle then :vehicles
                       end

            @selector_group.value = object.type
          else
            @selector_group.value = :erase
          end
        end

      when :walls
        @selector_group.value = wall.type if wall

      else
        raise tab
    end
  end

  public
  def icon_for(type, list_type = tab)
    if type == :erase or type == :none
      nil
    else
      klass = OBJECT_TYPES[list_type][:type]
      spritesheet_position = if list_type == :walls
                               klass.config[type][:spritesheet_positions][:vertical]
                             else
                               klass.config[type][:spritesheet_position]
                             end

      klass.sprites[*spritesheet_position]
    end
  end

  protected
  def list_window(list_type)
    erase_name = [:tiles, :walls].include?(list_type) ? :none : :erase

    buttons = group do
      vertical padding: 1 do
        radio_button 'Erase', erase_name

        grid padding: 0, num_columns: OBJECT_TYPES[list_type][:num_columns] do
          OBJECT_TYPES[list_type][:type].config.each_pair.sort.each do |type, config|
            icon = icon_for(type, list_type)
            next unless icon

            radio_button '', type, icon: icon, padding: 0,
                         icon_options: { factor: OBJECT_TYPES[list_type][:factor]  },
                         tip: "#{list_type.capitalize}: #{type} #{list_type == :entities ? "(#{config[:faction]})" : ''}"
          end
        end
      end
    end

    buttons.value = erase_name
  end
end
end
end