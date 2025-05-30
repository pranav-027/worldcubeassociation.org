# frozen_string_literal: true

module PersonsHelper
  def rank_td(rank_object, type)
    rank = rank_object&.public_send("#{type}_rank")
    rank = "-" if rank&.zero?
    content_tag :td, rank, class: "#{type}-rank #{'record' if rank == 1}"
  end

  def odd_rank_reason
    ui_icon("question circle", title: t("persons.show.odd_rank_reason"), data: { toggle: "tooltip" })
  end

  def odd_rank_reason_needed?(rank_single, rank_average)
    odd_rank?(rank_single) || (rank_average && odd_rank?(rank_average))
  end

  def odd_rank?(rank)
    any_missing = rank.continent_rank.zero? || rank.country_rank.zero? # NOTE: world rank is always present.
    any_missing || rank.continent_rank < rank.country_rank
  end

  def return_podium_class(result)
    return unless %w[f c].include?(result.round_type_id) && !result.best_solve.dnf?

    case result.pos
    when 1
      "gold-place"
    when 2
      "silver-place"
    when 3
      "bronze-place"
    end
  end
end
