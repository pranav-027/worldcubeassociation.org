# frozen_string_literal: true

module RegistrationsHelper
  def fees_hint_and_context(registration)
    if registration.competition.payments_enabled?
      if registration.outstanding_entry_fees <= 0
        [t('registrations.entry_fees_fully_paid', paid: format_money(registration.paid_entry_fees)), "success"]
      else
        [t('registrations.will_pay_here'), "info"]
      end
    else
      [t('registrations.wont_pay_here'), "info"]
    end
  end

  def notify_of_preferred_events(registration)
    if registration.persisted?
      # If they already registered, don't bother telling them about the
      # preferred events feature.
      ""
    elsif registration.user.preferred_events.empty?
      t('registrations.preferred_events_prompt_html', link: link_to(t('common.here'), profile_edit_path(section: :preferences)))
    else
      t('registrations.preferred_events_populated_html', link: link_to(t('common.here'), profile_edit_path(section: :preferences)))
    end
  end

  def please_sign_in(message_key, **args)
    sign_in = I18n.t('registrations.sign_in')
    here = I18n.t('common.here')
    args[:sign_in] = link_to(sign_in, new_user_session_path)
    args[:here] = link_to(here, new_user_registration_path, target: "_blank", rel: "noopener")
    raw(I18n.t(message_key, **args))
  end

  def name_for_payment(registration_payment)
    if registration_payment.user
      link_to(registration_payment.user.name, edit_user_path(registration_payment.user))
    else
      "<unknown user>"
    end
  end
end
