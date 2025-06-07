# frozen_string_literal: true

WickedPdf.config ||= {}

WickedPdf.config.merge!(
  layout: 'pdf.html', # your custom layout file app/views/layouts/pdf.html.erb
  exe_path: Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf') # path to wkhtmltopdf binary
)
