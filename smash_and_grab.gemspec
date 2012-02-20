# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "smash_and_grab"
  s.version = "0.0.6alpha"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bil Bas (Spooner)"]
  s.date = "2012-02-20"
  s.description = "Turn-based isometric heist game\n"
  s.email = ["bil.bagpuss@gmail.com"]
  s.executables = ["smash_and_grab"]
  s.files = ["bin/smash_and_grab", "bin/smash_and_grab.rbw", "config/gui", "config/gui/schema.yml", "config/lang", "config/lang/objects", "config/lang/objects/entities", "config/lang/objects/entities/en.yml", "config/lang/objects/static", "config/lang/objects/static/en.yml", "config/lang/objects/vehicles", "config/lang/objects/vehicles/en.yml", "config/levels", "config/levels/01_bank.sgl", "config/levels/01_bank.sgl.json", "config/map", "config/map/combat_dice.yml", "config/map/entities.yml", "config/map/objects.yml", "config/map/statuses.yml", "config/map/tiles.yml", "config/map/vehicles.yml", "config/map/walls.yml", "lib/smash_and_grab", "lib/smash_and_grab/abilities", "lib/smash_and_grab/abilities/ability.rb", "lib/smash_and_grab/abilities/area.rb", "lib/smash_and_grab/abilities/drop.rb", "lib/smash_and_grab/abilities/melee.rb", "lib/smash_and_grab/abilities/move.rb", "lib/smash_and_grab/abilities/pick_up.rb", "lib/smash_and_grab/abilities/ranged.rb", "lib/smash_and_grab/abilities/sprint.rb", "lib/smash_and_grab/abilities.rb", "lib/smash_and_grab/chingu_ext", "lib/smash_and_grab/chingu_ext/basic_game_object.rb", "lib/smash_and_grab/combat_effects.rb", "lib/smash_and_grab/fidgit_ext", "lib/smash_and_grab/fidgit_ext/container.rb", "lib/smash_and_grab/fidgit_ext/cursor.rb", "lib/smash_and_grab/fidgit_ext/element.rb", "lib/smash_and_grab/game_window.rb", "lib/smash_and_grab/gosu_ext", "lib/smash_and_grab/gosu_ext/font.rb", "lib/smash_and_grab/gui", "lib/smash_and_grab/gui/editor_selector.rb", "lib/smash_and_grab/gui/entity_panel.rb", "lib/smash_and_grab/gui/entity_summary.rb", "lib/smash_and_grab/gui/game_log.rb", "lib/smash_and_grab/gui/info_panel.rb", "lib/smash_and_grab/gui/minimap.rb", "lib/smash_and_grab/gui/object_panel.rb", "lib/smash_and_grab/gui/scenario_panel.rb", "lib/smash_and_grab/history", "lib/smash_and_grab/history/action_history.rb", "lib/smash_and_grab/history/editor_actions", "lib/smash_and_grab/history/editor_actions/erase_object.rb", "lib/smash_and_grab/history/editor_actions/place_object.rb", "lib/smash_and_grab/history/editor_actions/set_tile_type.rb", "lib/smash_and_grab/history/editor_actions/set_wall_type.rb", "lib/smash_and_grab/history/editor_action_history.rb", "lib/smash_and_grab/history/game_actions", "lib/smash_and_grab/history/game_actions/ability.rb", "lib/smash_and_grab/history/game_actions/end_turn.rb", "lib/smash_and_grab/history/game_action_history.rb", "lib/smash_and_grab/log.rb", "lib/smash_and_grab/main.rb", "lib/smash_and_grab/map", "lib/smash_and_grab/map/faction.rb", "lib/smash_and_grab/map/map.rb", "lib/smash_and_grab/map/tile.rb", "lib/smash_and_grab/map/wall.rb", "lib/smash_and_grab/mixins", "lib/smash_and_grab/mixins/has_contents.rb", "lib/smash_and_grab/mixins/has_status.rb", "lib/smash_and_grab/mixins/line_of_sight.rb", "lib/smash_and_grab/mixins/pathfinding.rb", "lib/smash_and_grab/mixins/rolls_dice.rb", "lib/smash_and_grab/mouse_selection.rb", "lib/smash_and_grab/objects", "lib/smash_and_grab/objects/entity.rb", "lib/smash_and_grab/objects/floating_text.rb", "lib/smash_and_grab/objects/static.rb", "lib/smash_and_grab/objects/vehicle.rb", "lib/smash_and_grab/objects/world_object.rb", "lib/smash_and_grab/path.rb", "lib/smash_and_grab/players", "lib/smash_and_grab/players/ai.rb", "lib/smash_and_grab/players/human.rb", "lib/smash_and_grab/players/player.rb", "lib/smash_and_grab/players/remote.rb", "lib/smash_and_grab/sprite_sheet.rb", "lib/smash_and_grab/states", "lib/smash_and_grab/states/edit_level.rb", "lib/smash_and_grab/states/main_menu.rb", "lib/smash_and_grab/states/play_level.rb", "lib/smash_and_grab/states/world.rb", "lib/smash_and_grab/statuses", "lib/smash_and_grab/statuses/status.rb", "lib/smash_and_grab/std_ext", "lib/smash_and_grab/std_ext/array.rb", "lib/smash_and_grab/std_ext/hash.rb", "lib/smash_and_grab/texplay_ext", "lib/smash_and_grab/texplay_ext/color.rb", "lib/smash_and_grab/texplay_ext/image.rb", "lib/smash_and_grab/texplay_ext/window.rb", "lib/smash_and_grab/version.rb", "lib/smash_and_grab/z_order.rb", "lib/smash_and_grab/z_order_recorder.rb", "lib/smash_and_grab.rb", "media/fonts", "media/fonts/fontinfo.txt", "media/fonts/UnmaskedBB.ttf", "media/icon.ico", "media/images", "media/images/dice0.png", "media/images/dice1.png", "media/images/dice2.png", "media/images/elements.png", "media/images/entities.png", "media/images/entity_portraits.png", "media/images/floor_tiles.png", "media/images/infinity16.png", "media/images/mouse_cursor.png", "media/images/mouse_hover.png", "media/images/mouse_hover_wall.png", "media/images/objects.png", "media/images/path.png", "media/images/resistances.png", "media/images/tiles_selection.png", "media/images/tile_selection.png", "media/images/vehicles.png", "media/images/vulnerabilities.png", "media/images/walls.png", "CHANGELOG.md", "README.md", "LICENSE.txt", "test/smash_and_grab/abilities/drop_test.rb", "test/smash_and_grab/abilities/melee_test.rb", "test/smash_and_grab/abilities/move_test.rb", "test/smash_and_grab/abilities/pick_up_test.rb", "test/smash_and_grab/abilities/ranged_test.rb", "test/smash_and_grab/abilities/sprint_test.rb", "test/smash_and_grab/map/faction_test.rb", "test/smash_and_grab/map/map_test.rb", "test/smash_and_grab/map/tile_test.rb", "test/smash_and_grab/map/wall_test.rb", "test/smash_and_grab/std_ext/hash_test.rb"]
  s.homepage = "http://spooner.github.com/games/smash_and_grab/"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("~> 1.9.2")
  s.rubyforge_project = "smash_and_grab"
  s.rubygems_version = "1.8.16"
  s.summary = "Turn-based isometric heist game"
  s.test_files = ["test/smash_and_grab/abilities/drop_test.rb", "test/smash_and_grab/abilities/melee_test.rb", "test/smash_and_grab/abilities/move_test.rb", "test/smash_and_grab/abilities/pick_up_test.rb", "test/smash_and_grab/abilities/ranged_test.rb", "test/smash_and_grab/abilities/sprint_test.rb", "test/smash_and_grab/map/faction_test.rb", "test/smash_and_grab/map/map_test.rb", "test/smash_and_grab/map/tile_test.rb", "test/smash_and_grab/map/wall_test.rb", "test/smash_and_grab/std_ext/hash_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<gosu>, ["~> 0.7.41"])
      s.add_runtime_dependency(%q<chingu>, ["~> 0.9rc7"])
      s.add_runtime_dependency(%q<fidgit>, ["~> 0.2.1"])
      s.add_runtime_dependency(%q<texplay>, ["~> 0.3"])
      s.add_runtime_dependency(%q<r18n-desktop>, ["~> 0.4.14"])
      s.add_development_dependency(%q<releasy>, ["~> 0.2.2"])
      s.add_development_dependency(%q<rake>, ["~> 0.9.2.2"])
      s.add_development_dependency(%q<bacon-rr>, ["~> 0.1.0"])
    else
      s.add_dependency(%q<gosu>, ["~> 0.7.41"])
      s.add_dependency(%q<chingu>, ["~> 0.9rc7"])
      s.add_dependency(%q<fidgit>, ["~> 0.2.1"])
      s.add_dependency(%q<texplay>, ["~> 0.3"])
      s.add_dependency(%q<r18n-desktop>, ["~> 0.4.14"])
      s.add_dependency(%q<releasy>, ["~> 0.2.2"])
      s.add_dependency(%q<rake>, ["~> 0.9.2.2"])
      s.add_dependency(%q<bacon-rr>, ["~> 0.1.0"])
    end
  else
    s.add_dependency(%q<gosu>, ["~> 0.7.41"])
    s.add_dependency(%q<chingu>, ["~> 0.9rc7"])
    s.add_dependency(%q<fidgit>, ["~> 0.2.1"])
    s.add_dependency(%q<texplay>, ["~> 0.3"])
    s.add_dependency(%q<r18n-desktop>, ["~> 0.4.14"])
    s.add_dependency(%q<releasy>, ["~> 0.2.2"])
    s.add_dependency(%q<rake>, ["~> 0.9.2.2"])
    s.add_dependency(%q<bacon-rr>, ["~> 0.1.0"])
  end
end
