# frozen_string_literal: true

class CronjobStatistic < ApplicationRecord
  self.primary_key = "name"

  def in_progress?
    self.run_start.present? && self.run_end.blank?
  end

  def finished?
    self.run_end.present?
  end

  def scheduled?
    self.enqueued_at.present?
  end
end
