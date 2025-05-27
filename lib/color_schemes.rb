# lib/color_schemes.rb
module ColorSchemes
  ELEGANT_ONYX = {
    primary: '#363636',      # Deep Charcoal
    secondary: '#a8dadc',    # Light Cyan
    accent: '#45a247',     # Forest Green
    text: '#f8f8f2',       # Off-White
    link_hover: '#c5e1a5',   # Lime Green
    active_link: '#e63946',  # Crimson
    dropdown_bg: '#4d4d4d', # Dark Gray
    dropdown_hover: '#616161', # Medium Gray
    border: 'rgba(255, 255, 255, 0.08)'
  }

  SERENE_LAVENDER = {
    primary: '#4a148c',      # Deep Purple
    secondary: '#e0b0ff',    # Mauve
    accent: '#64b5f6',     # Light Blue
    text: '#f3e5f5',       # Light Lavender
    link_hover: '#b388ff',   # Violet
    active_link: '#f06292',  # Pink
    dropdown_bg: '#6a1b9a', # Darker Purple
    dropdown_hover: '#8e24aa', # Medium Purple
    border: 'rgba(255, 255, 255, 0.08)'
  }

  GILDED_SAND = {
    primary: '#4e342e',      # Dark Brown
    secondary: '#ffb300',    # Amber
    accent: '#a1887f',     # Taupe
    text: '#fbe9e7',       # Light Beige
    link_hover: '#ffca28',   # Gold
    active_link: '#d84315',  # Deep Orange
    dropdown_bg: '#6d4c41', # Darker Brown
    dropdown_hover: '#8d6e63', # Medium Brown
    border: 'rgba(255, 255, 255, 0.08)'
  }

  MISTY_ROSE = {
    primary: '#263238',      # Dark Slate Gray
    secondary: '#f48fb1',    # Pink
    accent: '#90caf9',     # Light Blue
    text: '#eceff1',       # Light Gray
    link_hover: '#ce93d8',   # Lilac
    active_link: '#e91e63',  # Deep Pink
    dropdown_bg: '#37474f', # Darker Slate Gray
    dropdown_hover: '#4f5b62', # Medium Slate Gray
    border: 'rgba(255, 255, 255, 0.08)'
  }

  # Keeping the previous vibrant options for variety
  MODERN_BLUE = {
    primary: '#2c3e50',
    secondary: '#3498db',
    accent: '#f39c12',
    text: '#ecf0f1',
    link_hover: '#5dade2',
    active_link: '#e74c3c',
    dropdown_bg: '#34495e',
    dropdown_hover: '#4a6572',
    border: 'rgba(255, 255, 255, 0.08)'
  }

  VIBRANT_PURPLE = {
    primary: '#6002EE',
    secondary: '#FF6F61',
    accent: '#00E676',
    text: '#F8F8FF',
    link_hover: '#7B1FA2',
    active_link: '#D32F2F',
    dropdown_bg: '#4A00E0',
    dropdown_hover: '#6A00C9',
    border: 'rgba(255, 255, 255, 0.08)'
  }

  SUNSET_ORANGE = {
    primary: '#ff8f00',
    secondary: '#ffcc80',
    accent: '#d84315',
    text: '#212121',
    link_hover: '#ffa000',
    active_link: '#e65100',
    dropdown_bg: '#e65100',
    dropdown_hover: '#f57c00',
    border: 'rgba(33, 33, 33, 0.08)'
  }

  COOL_TEAL = {
    primary: '#008080',
    secondary: '#80cbc4',
    accent: '#b2ebf2',
    text: '#e0f2f7',
    link_hover: '#26a69a',
    active_link: '#00695c',
    dropdown_bg: '#006064',
    dropdown_hover: '#00838f',
    border: 'rgba(224, 242, 247, 0.08)'
  }

  NEON_DREAM = {
    primary: '#171717',
    secondary: '#4affff',
    accent: '#d400ff',
    text: '#f0f0f0',
    link_hover: '#6affff',
    active_link: '#e74c3c',
    dropdown_bg: '#2e2e2e',
    dropdown_hover: '#444',
    border: 'rgba(255, 255, 255, 0.08)'
  }

  EMERALD_SUNSET = {
    primary: '#004d40',
    secondary: '#ffab40',
    accent: '#aed581',
    text: '#f5f5f5',
    link_hover: '#26a69a',
    active_link: '#ff8f00',
    dropdown_bg: '#003333',
    dropdown_hover: '#005a5a',
    border: 'rgba(255, 255, 255, 0.08)'
  }

  MIDNIGHT_BLOOM = {
    primary: '#212121',
    secondary: '#f48fb1',
    accent: '#9c27b0',
    text: '#e0f7fa',
    link_hover: '#ce93d8',
    active_link: '#e91e63',
    dropdown_bg: '#424242',
    dropdown_hover: '#616161',
    border: 'rgba(255, 255, 255, 0.08)'
  }

  AQUA_TWILIGHT = {
    primary: '#22223b',
    secondary: '#8ac4ff',
    accent: '#ffbaba',
    text: '#f8f9fa',
    link_hover: '#aed6ff',
    active_link: '#ff6f61',
    dropdown_bg: '#4a4a6a',
    dropdown_hover: '#636385',
    border: 'rgba(255, 255, 255, 0.08)'
  }

  SCHEMES = {
    elegant_onyx: ELEGANT_ONYX,
    serene_lavender: SERENE_LAVENDER,
    gilded_sand: GILDED_SAND,
    misty_rose: MISTY_ROSE,
    modern_blue: MODERN_BLUE,
    vibrant_purple: VIBRANT_PURPLE,
    sunset_orange: SUNSET_ORANGE,
    cool_teal: COOL_TEAL,
    neon_dream: NEON_DREAM,
    emerald_sunset: EMERALD_SUNSET,
    midnight_bloom: MIDNIGHT_BLOOM,
    aqua_twilight: AQUA_TWILIGHT
  }

  # Default theme set to one of the elegant options
  DEFAULT_THEME = :elegant_onyx
end
