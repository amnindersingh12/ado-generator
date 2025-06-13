# app/lib/color_schemes.rb

module ColorSchemes
  DEFAULT_THEME = :light

  SCHEMES = {
    light: {
      primary: '#4682B4', # Steel Blue: A sophisticated, slightly desaturated blue
      primary_rgb: '70, 130, 180', # Add RGB for primary color
      secondary: '#778899', # Light Slate Gray: A soft, muted grey for secondary elements
      accent: '#50C878', # Emerald Green: A fresh, natural green for highlights and success states
      accent_rgb: '80, 200, 120', # Add RGB for accent color
      text: '#FFFFFF', # White text (for primary background elements like navbars, buttons)
      link_hover: 'rgba(255, 255, 255, 0.12)', # Lighter hover for dark primary
      active_link: 'rgba(255, 255, 255, 0.25)', # More visible active for dark primary
      dropdown_bg: '#2F4F4F', # Dark Slate Gray: A deep, rich, almost black-green for dropdowns
      dropdown_hover: '#4F6F6F', # Slightly lighter hover for dropdown
      border: 'rgba(255, 255, 255, 0.35)', # Lighter border for dark primary
      body_bg: '#F0F8FF', # Alice Blue: The soft, refreshing main background
      body_text: '#36454F', # Charcoal: A dark, legible, yet soft text color for general content
      card_bg: '#FFFFFF', # Pure White: Provides clear separation and "lift" for cards against the Alice Blue
      card_border: '#E0E7ED' # A very light, cool grey for card borders
    },
    dark: {
      primary: '#212529', # Deep Charcoal: Main background for dark sidebar/header
      primary_rgb: '33, 37, 41', # Add RGB for primary color
      secondary: '#adb5bd', # Muted light grey for secondary text in dark mode
      accent: '#66b2ff', # Lighter blue for highlights in dark mode
      accent_rgb: '102, 178, 255', # Add RGB for accent color
      text: '#e9ecef', # Light grey for text on dark primary elements
      link_hover: 'rgba(255, 255, 255, 0.08)',
      active_link: 'rgba(255, 255, 255, 0.15)',
      dropdown_bg: '#343a40', # Darker grey for dropdowns
      dropdown_hover: '#495057', # Slightly lighter hover for dropdown
      border: 'rgba(255, 255, 255, 0.15)',
      body_bg: '#343a40', # Dark grey for the main content background
      body_text: '#e9ecef', # Light text for general content in dark mode
      card_bg: '#2c3034', # Darker card background for contrast
      card_border: '#495057' # Darker border for cards
    }
  }.freeze

  # Helper to convert hex to RGB string (e.g., "#RRGGBB" to "R, G, B")
  # This can be used if you prefer to define only hex and calculate RGB on the fly,
  # but pre-defining them is often simpler for static schemes.
  def self.hex_to_rgb(hex)
    hex = hex.delete('#')
    return unless hex.length == 6

    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)
    "#{r}, #{g}, #{b}"
  end
end