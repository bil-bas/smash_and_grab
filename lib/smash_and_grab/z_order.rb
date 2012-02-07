module SmashAndGrab
class ZOrder
  BACKGROUND = -Float::INFINITY
  TILES = -99_999
  SHADOWS = -99_998
  TILE_SELECTION = -99_997
  PATH = -99_996
  # Objects -1_000 .. +1_000

  BEHIND_GUI = 1_000_000
  GUI = Float::INFINITY
end
end