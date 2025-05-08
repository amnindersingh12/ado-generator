module ApplicationHelper
  def format_datetime(time)
    time.strftime("%m/%d/%Y at %H:%M:%S")
  end
  def is_admin(user)
    user.role=="admin"
  end
  def webcam_capture(form, field)
    render partial: "shared/webcam_capture", locals: { form: form, field: field }
  end
end

  def enlargeable_image_tag(image, id: nil, thumb_size: "100px", modal_size: "lg", label: nil)
    return unless image.attached?

    modal_id = "imageModal-#{id || SecureRandom.hex(4)}"

    thumbnail = image_tag(
      image,
      style: "max-width: #{thumb_size}; cursor: pointer;",
      data: { bs_toggle: "modal", bs_target: "##{modal_id}" },
      class: "img-thumbnail"
    )

    modal = content_tag(:div, class: "modal fade", id: modal_id, tabindex: "-1", aria: { hidden: true }) do
      content_tag(:div, class: "modal-dialog modal-dialog-centered modal-#{modal_size}") do
        content_tag(:div, class: "modal-content") do
          content_tag(:div, class: "modal-body text-center") do
            image_tag(image, class: "img-fluid") +
              (label.present? ? content_tag(:p, label, class: "mt-2") : "")
          end
        end
      end
    end

    thumbnail + modal
  end
