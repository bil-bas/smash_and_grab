Releasy::Project.new do
  name "Smash and Grab"
  version SmashAndGrab::VERSION
  executable "bin/smash_and_grab.rbw"
  files `git ls-files`.split("\n")
  files.exclude *%w[.gitignore build/**/*.* raw_media/**/*.* saves/**/*.* test/**/*.* media/icon.* smash_and_grab.gemspec_]

  exposed_files %w[README.md]
  add_link "http://spooner.github.com/games/smash_and_grab", "Smash and Grab website"
  exclude_encoding

  add_build :osx_app do
    wrapper "../releasy/wrappers/gosu-mac-wrapper-0.7.41.tar.gz"
    url "com.github.spooner.games.smash_and_grab"
    icon "media/icon.icns"
    add_package :tar_gz
  end

  add_build :source do
    add_package :zip
  end

  add_build :windows_folder do
    icon "media/icon.ico"
    add_package :exe
  end

  add_build :windows_installer do
    icon "media/icon.ico"
    start_menu_group "Spooner Games"
    readme "README.html"
    add_package :zip
  end

  add_deploy :local do
    path "C:/users/spooner/dropbox/Public/games/smash_and_grab"
  end
end