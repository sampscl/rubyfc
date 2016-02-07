module Paidgeeks
  class PidState
    #
    # Get state of a process identified by pid
    # <b>Parameters</b>
    # - pid => A process identifier
    # <b>Returns</b>
    # - :alive => the pid is alive
    # - :dead => the pid is dead (no such pid exists)
    # - :zombie => the pid is dead but has not bee reaped yet (you probably need to call Process.detatch(pid))
    #
    def self.pid_state(pid)
      result = `ps -o state,pid,%cpu,cmd -p #{pid} --no-headers`
      return :dead if result.length == 0
      result =~ /^[^Zz]/ ? :alive : :zombie
    end
  end
end
