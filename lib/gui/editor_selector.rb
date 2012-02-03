module SmashAndGrab
module Gui
class EditorSelector < Fidgit::Vertical
  OBJECT_TABS = [:tiles, :walls, :objects, :entities, :vehicles]

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
            send("#{value}_window")
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

  protected
  def tiles_window
    buttons = group do
      vertical padding: 1 do
        radio_button 'Erase', :none
        grid padding: 0, num_columns: 2 do
          Tile.config.each_pair.sort.each do |type, data|
            next if type == :none
            radio_button '', type, icon: Tile.sprites[*data[:spritesheet_position]],
                         tip: "Tile: #{type}", padding: 0, icon_options: { factor: 2 }
          end
        end
      end
    end

    buttons.value = :none
  end

  protected
  def entities_window
    buttons = group do
      vertical padding: 1 do
        radio_button 'Erase', :erase
        grid padding: 0, num_columns: 2 do
          Objects::Entity.config.each_pair.sort.each do |type, data|
            radio_button '', type, icon: Objects::Entity.sprites[*data[:spritesheet_position]],
                         tip: "Entity: #{type} (#{data[:faction]})", padding: 0
          end
        end
      end
    end

    buttons.value = :erase
  end

  protected
  def objects_window
    buttons = group do
      vertical padding: 1 do
        radio_button 'Erase', :erase
        grid padding: 0, num_columns: 2 do
          Objects::Static.config.each_pair.sort.each do |type, data|
            radio_button '', type, icon: Objects::Static.sprites[*data[:spritesheet_position]],
                         tip: "Object: #{type}", padding: 0
          end
        end
      end
    end

    buttons.value = :erase
  end

  protected
  def vehicles_window
    buttons = group do
      vertical padding: 1 do
        radio_button 'Erase', :erase
        grid padding: 0, num_columns: 1 do
          Objects::Vehicle.config.each_pair.sort.each do |type, data|
            radio_button '', type, icon: Objects::Vehicle.sprites[*data[:spritesheet_position]],
                         tip: "Vehicle: #{type}", padding: 0, icon_options: { factor: 0.5 }
          end
        end
      end
    end

    buttons.value = :erase
  end

  protected
  def walls_window
    buttons = group do
      vertical padding: 1 do
        radio_button 'Erase', :none
        grid padding: 0, num_columns: 3 do
          Wall.config.each_pair.sort.each do |type, data|
            next if type == :none
            radio_button '', type, icon: Wall.sprites[*(data[:spritesheet_positions][:vertical])],
                         tip: "Wall: #{type}", padding: 0
          end
        end
      end
    end

    buttons.value = :none
  end
end
end
end