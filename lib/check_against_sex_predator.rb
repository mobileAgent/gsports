#
# Check users' information against databases of sexual predators
# This is meant to be run in the Rails environment with script/runner:
# ruby ./script/runner "CheckAgainSexPredator.do_check"
#

class CheckAgainstSexPredator
  def self.do_check
    SorSearchLog.do_search
  end
end