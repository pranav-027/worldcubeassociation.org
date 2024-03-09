# frozen_string_literal: true

class RoleChangeMailer < ApplicationMailer
  private def role_metadata(role)
    metadata = {}

    # Populate the metadata list.
    case role.group.group_type
    when UserGroup.group_types[:delegate_regions]
      metadata[:region_name] = role.group.name
      metadata[:status] = I18n.t("enums.user.role_status.delegate_regions.#{role.metadata.status}")
    when UserGroup.group_types[:translators]
      metadata[:locale] = role.group.metadata.locale
    end
    metadata
  end

  def notify_role_start(role, user_who_made_the_change)
    @role = role
    @user_who_made_the_change = user_who_made_the_change
    @group_type_name = UserGroup.group_type_name[@role.group.group_type.to_sym]
    @metadata = role_metadata(role)

    # Populate the recepient list.
    case role.group.group_type
    when UserGroup.group_types[:delegate_probation]
      to_list = [user_who_made_the_change.email, Team.board.email, role.user.senior_delegates.map(&:email)].flatten
      reply_to_list = [user_who_made_the_change.email]
    when UserGroup.group_types[:delegate_regions]
      to_list = [user_who_made_the_change.email, Team.board.email, Team.weat.email, Team.wfc.email]
      reply_to_list = [user_who_made_the_change.email]
    else
      raise "Unknown/Unhandled group type: #{role.group.group_type}"
    end

    # Send email.
    mail(
      to: to_list.compact.uniq,
      reply_to: reply_to_list.compact.uniq,
      subject: "New role added for #{role.user.name} in #{@group_type_name}",
    )
  end

  def notify_role_end(role, user_who_made_the_change)
    @role = role
    @user_who_made_the_change = user_who_made_the_change
    @group_type_name = UserGroup.group_type_name[@role.group.group_type.to_sym]
    @metadata = role_metadata(role)

    # Populate the recepient list.
    case role.group.group_type
    when UserGroup.group_types[:delegate_regions]
      to_list = [user_who_made_the_change.email, Team.board.email, Team.weat.email, Team.wfc.email]
      reply_to_list = [user_who_made_the_change.email]
    when UserGroup.group_types[:translators]
      to_list = [user_who_made_the_change.email, Team.wst.email]
      reply_to_list = [user_who_made_the_change.email]
    else
      raise "Unknown/Unhandled group type: #{role.group.group_type}"
    end

    # Send email.
    mail(
      to: to_list.compact.uniq,
      reply_to: reply_to_list.compact.uniq,
      subject: "Role removed for #{role.user.name} in #{@group_type_name}",
    )
  end

  def notify_change_probation_end_date(role, user_who_made_the_change)
    @role = role
    @user_who_made_the_change = user_who_made_the_change

    mail(
      to: [user_who_made_the_change.email, Team.board.email, role.user.senior_delegates.map(&:email)].flatten.compact.uniq,
      reply_to: [user_who_made_the_change.email].compact.uniq,
      subject: "Delegate Probation end date changed for #{role.user.name}",
    )
  end
end