class EditorSelector < Fidgit::Vertical
  OBJECT_TABS = [:tiles, :entities, :objects, :walls]

  def tab; @tabs_group.value; end
  def selected; @selector_group.value ;end

  def initialize(options = {})
    options = {
        padding: 1,
        background_color: Color::BLACK,
    }.merge! options

    super options

    vertical padding: 0, spacing: 0 do
      @tabs_group = group do
        @tab_buttons = horizontal padding: 0, spacing: 1 do
          OBJECT_TABS.each do |name|
            radio_button(name.to_s[0].capitalize, name, border_thickness: 0, padding: 2, tip: name.to_s.capitalize)
          end
        end

        subscribe :changed do |sender, value|
          current = @tab_buttons.find {|elem| elem.value == value }
          @tab_buttons.each {|t| t.enabled = (t != current) }
          current.color, current.background_color = current.background_color, current.color

          self.tab = value
        end
      end

      @tab_contents = vertical padding: 0 do
         # Put the tab contents in here at a later date.
      end
    end

    @tabs_group.value = OBJECT_TABS.first
  end

  def pick_up(tile, wall)
    case tab
      when :tiles
        @selector_group.value = tile.type if tile

      when :entities, :objects
        if tile
          object = tile.object
          if object
            if tab == :entities and not object.is_a?(Entity)
              self.tab = :objects
            elsif tab == :objects and not object.is_a?(StaticObject)
              self.tab = :entities
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
  def tab=(tab)
    @tab_contents.clear

    scroll_options = { width: 50, height: 135 }

    case tab
      when :tiles
        unless defined? @tiles_window
          @tiles_window = Fidgit::ScrollWindow.new scroll_options do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', 'none'
                grid padding: 0, num_columns: 2 do
                  Tile.config.each_pair.sort.each do |type, data|
                    next if type == 'none'
                    radio_button '', type, icon: Tile.sprites[*data['spritesheet_position']],
                                 tip: "Tile: #{type}", padding: 0, icon_options: { factor: 0.5 }
                  end
                end
              end
            end

            buttons.value = 'none'
          end
        end

        @selector_window = @tiles_window

      when :entities
        unless defined? @entities_window
          @entities_window = Fidgit::ScrollWindow.new scroll_options do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', :erase
                grid padding: 0, num_columns: 2 do

                  Entity.config.each_pair.sort.each do |type, data|
                    radio_button '', type, icon: Entity.sprites[*data['spritesheet_position']],
                                 tip: "Entity: #{type} (#{data['faction']})", padding: 0, icon_options: { factor: 0.25 }
                  end
                end
              end
            end

            buttons.value = :erase
          end
        end

        @selector_window = @entities_window

      when :objects
        unless defined? @objects_window
          @objects_window = Fidgit::ScrollWindow.new scroll_options do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', :erase
                grid padding: 0, num_columns: 2 do

                  StaticObject.config.each_pair.sort.each do |type, data|
                    radio_button '', type, icon: StaticObject.sprites[*data['spritesheet_position']],
                                 tip: "Object: #{type}", padding: 0, icon_options: { factor: 0.25 }
                  end
                end
              end
            end

            buttons.value = :erase
          end
        end

        @selector_window = @objects_window

      when :walls
        unless defined? @walls_window
          @walls_window = Fidgit::ScrollWindow.new scroll_options do
            buttons = group do
              vertical padding: 1 do
                radio_button 'Erase', 'none'
                grid padding: 0, num_columns: 3 do
                  Wall.config.each_pair.sort.each do |type, data|
                    next if type == 'none'
                    radio_button '', type, icon: Wall.sprites[*(data['spritesheet_positions']['vertical'])],
                                 tip: "Wall: #{type}", padding: 0, icon_options: { factor: 0.25 }
                  end
                end
              end
            end

            buttons.value = 'none'
          end
        end

        @selector_window = @walls_window

      else
        raise tab.to_s
    end

    @tab_contents.add @selector_window
    @selector_group = @selector_window.content[0]
  end
end