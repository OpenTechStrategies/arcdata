class Roster::Position < ActiveRecord::Base
  belongs_to :chapter
  has_many :position_memberships

  serialize :role_scope

  def vc_regex
    @compiled_regex ||= Regexp.new(vc_regex_raw)
  end
end
