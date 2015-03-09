require 'json'
require 'zabbix/client'
require "formatador"
require 'pp'

HOST = ENV['ZBXHOST'] ? ENV['ZBXHOST'] : "127.0.0.1"
USERNAME = ENV['ZBXUSER'] ? ENV['ZBXUSER'] : "Admin"
PASSWORD = ENV['ZBXPASS'] ? ENV['ZBXPASS'] : "zabbix"

opt1 = ARGV[0]
opt2 = ARGV[1]
opt3 = ARGV[2]

class ZBX

  def initialize()
    @zabbix = Zabbix::Client.new("http://#{HOST}/zabbix/api_jsonrpc.php")
    begin
      @zabbix.user.login(user: USERNAME, password: PASSWORD)
    rescue => e
      puts "Failed login to #{HOST}"
      puts e
      exit
    end
  end

  def host_list(hostid)
    if hostid == "all"
      hostlist = @zabbix.host.get(
      :output => "extend"
      )
    else
      hostlist = @zabbix.host.get(
      :hostids => hostid,
      :output => "extend"
      )
    end

    data = Array.new

    hostlist.each do | h|
      interface = @zabbix.hostinterface.get(hostid: h['hostid']).first['ip']
      if h['status'] == "1"
        status = "disable"
      elsif h['status'] == "0"
        status = "enable"
      end
      data << {:id => h['hostid'], :name => h['name'], :interface => interface, :status => status}
    end
    # p data.first
    Formatador.display_compact_table(data, [:id, :name, :interface, :status])
    data
  end

  def host_enable(hostid)
    begin
      @zabbix.host.update(
      :hostid => hostid,
      :status => "0"
      )
      host_list(hostid)
    rescue => e
      msg = "HostID #{hostid} not found.\n #{e}"
      puts msg
      msg
    end
  end

  def host_disable(hostid)
    begin
      @zabbix.host.update(
      :hostid => hostid,
      :status => "1"
      )
      host_list(hostid)
    rescue => e
      msg = "HostID #{hostid} not found.\n #{e}"
      puts msg
      msg
    end
  end

  def host_delete(hostid)
    begin
      host = @zabbix.host.get(
      :hostids => hostid,
      ).first
      print "Are you sure you want to delete \'#{host['name']}\'? [Y/N] : "
    rescue => e
      puts "HostID #{hostid} not found."
      puts e
      exit
    end
    if STDIN.getc.downcase == "y"
      begin
        @zabbix.host.delete([hostid])
      rescue
        puts "Cannot delete #{host{'name'}}"
        puts e
      end
    end
  end



end

def print_host_usage
  puts <<-EOS
  Usage :
  #{$0} host list
  #{$0} host enable (HOSTID)
  #{$0} host disable (HOSTID)
  #{$0} host delete (HOSTID)
  EOS
  exit
end

case opt1
when "host"
  case opt2
  when "list"
    ZBX.new.host_list("all")
  when "enable"
    print_host_usage if(!opt3)
    ZBX.new.host_enable(opt3)
  when "disable"
    print_host_usage if(!opt3)
    ZBX.new.host_disable(opt3)
  when "delete"
    print_host_usage if(!opt3)
    ZBX.new.host_delete(opt3)
  else
    print_host_usage
  end
end
