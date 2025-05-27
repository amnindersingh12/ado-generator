# frozen_string_literal: true

require 'rqrcode'
require 'chunky_png' # needed to render PNG from QR

module AttendancesHelper
  # Convert an attached ActiveStorage image to base64 format
  def base64_image_tag(photo, options = {})
    return unless photo.attached?

    image_data = "data:#{photo.content_type};base64,#{Base64.strict_encode64(photo.download)}"

    # Extract and convert size option if present (e.g., "120x120")
    if options[:size]
      width, height = options[:size].split('x')
      options[:width] = width
      options[:height] = height
      options.delete(:size)
    end

    image_tag(image_data, { alt: 'User Photo' }.merge(options))
  end

  # Format datetime in DD-MM-YYYY HH:MM:SS format
  def format_datetime(datetime)
    datetime&.strftime('%d-%m-%Y %H:%M:%S') || 'N/A'
  end

  # Show user token or fallback to ID
  def display_token(attendance)
    attendance.id
  end

  def attendance_qr_code_base64(attendance)
    data = {
      id: attendance.id,
      name: attendance.record.name,
      address: attendance.record.address,
      government_id: attendance.record.government_id_number,
      purpose: attendance.purpose,
      contact_number: attendance.record.contact_number,
      action: attendance.out_time.present? ? 'Check-Out' : 'Check-In',
      in_time: format_datetime(attendance.in_time),
      out_time: format_datetime(attendance.out_time)
    }

    qr = RQRCode::QRCode.new(data.to_json)

    png = qr.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 240
    )

    base64 = Base64.strict_encode64(png.to_s)

    image_tag "data:image/png;base64,#{base64}", alt: 'QR Code', class: 'qr-code'
  end

  # def time_spent(attendance)
  #   unless attendance.in_time && attendance.out_time
  #     return 'Incomplete attendance'
  #   end

  #   time_diff = (attendance.out_time - attendance.in_time).abs

  #   return 'Less than a min' if time_diff < 60

  #   hours, remainder = time_diff.divmod(3600)
  #   minutes, _seconds = remainder.divmod(60)

  #   "#{hours}h #{minutes}m"
  # end

  def time_spent(total_seconds)
    return 'Incomplete attendance' unless total_seconds.is_a?(Numeric) && total_seconds >= 0

    return 'Less than a min' if total_seconds < 60

    hours, remainder = total_seconds.divmod(3600)
    minutes, _seconds = remainder.divmod(60)

    "#{hours}h #{minutes}m"
  end




end
