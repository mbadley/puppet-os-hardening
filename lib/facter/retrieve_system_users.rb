# Try to read UID_MIN from /etc/login.defs to caluclate SYS_UID_MAX
# if that fails set some predefined values based on os_family fact.
logindefs = '/etc/login.defs'

if File.exist?(logindefs)
  f = File.open(logindefs, 'r')
  su_maxid = f.each do |line|
    break Regexp.last_match[1].to_i - 1 if line =~ /^\s*UID_MIN\s+(\d+)(\s*#.*)?$/
  end
  f.close
else
  case Facter.value(:osfamily)
  when 'Debian', 'OpenBSD', 'FreeBSD'
    su_maxid = 999
  else
    su_maxid = 499
  end
end

# Retrieve all system users and build custom fact with the usernames
# using comma separated values.
Facter.add(:retrieve_system_users) do
  sys_users = []
  Puppet::Type.type('user').instances.find_all do |user|
    user_value = user.retrieve
    sys_users.push(user.name) unless user_value[user.property(:uid)].to_i > su_maxid
  end
  setcode do
    sys_users.join(',')
  end
end
