require 'json'
require 'zabbix/client'
require "formatador"
require 'rexml/document'
require 'rexml/formatters/pretty'
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
      :output => "extend",
      :selectGroups => "extend",
      :selectParentTemplates => ["templateid"]
    )
    else
      hostlist = @zabbix.host.get(
      :hostids => hostid,
      :output => "extend",
      :selectGroups => "extend",
      :selectParentTemplates => ["templateid"]
      )
    end

    data = Array.new

    hostlist.each do |h|
      interface = @zabbix.hostinterface.get(hostid: h['hostid']).first['ip']
      if h['status'] == "1"
        status = "disable"
      elsif h['status'] == "0"
        status = "enable"
      end
      groups = Array.new
      h['groups'].each do |g|
        groups << g['groupid'].to_i
      end
      templates = Array.new
      h['parentTemplates'].each do |t|
        templates << t['templateid'].to_i
      end
      data << {:id => h['hostid'], :name => h['name'], :group => groups, :interface => interface, :status => status, :template => templates}
    end
    Formatador.display_compact_table(data, [:id, :name, :group, :interface, :status, :template])
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

  def template_list(templateid)
    if templateid == "all"
      templatelist = @zabbix.template.get(
        :output => "extend"
      )
    else
      templatelist = @zabbix.template.get(
        :templateids => templateid,
        :output => "extend"
      )
    end
    data = Array.new
    templatelist.each do |t|
      data << {:id => t['templateid'], :name => t['name']}
    end
    if data.length == 0
      msg = "TemplateID #{templateid} not found.\n"
      puts msg
      msg
    else
      Formatador.display_compact_table(data, [:id, :name])
      data
    end
  end

  def template_export(templateid)
    template = @zabbix.template.get(
      :templateids => templateid,
      :output => "extend"
    )
    if template.length == 0
      msg = "TemplateID #{templateid} not found.\n"
      puts msg
      msg
    else
      template_filename = template[0]["host"] + ".xml"

      template_xml = @zabbix.configuration.export(
        :options => { :templates => [templateid] },
        :format => 'xml'
      )

      xml = REXML::Document.new template_xml
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true

      begin
        File.open(template_filename ,"w"){|file| file.puts formatter.write(xml.root,"")}
        puts "export to #{template_filename}"
      rescue => e
        puts "Failed export to #{template_filename}"
        puts e
        exit
      end
    end
  end

  def template_import(template_file)
    begin
      template = File.read("#{template_file}")
    rescue => e
      puts "Failed import #{template_file}"
      puts e
      exit
    end
    begin
      @zabbix.configuration.import(
      :rules => {
        :applications => {
          :createMissing => true,
          :updateExisting => true
        },
        :discoveryRules => {
          :createMissing => true,
          :updateExisting => true
        },
        :graphs  => {
          :createMissing => true,
          :updateExisting => true
        },
        :groups => {
          :createMissing => true,
        },
        :hosts => {
          :createMissing => true,
          :updateExisting => true
        },
        :images => {
          :createMissing => true,
          :updateExisting => true
        },
        :items => {
          :createMissing => true,
          :updateExisting => true
        },
        :maps => {
          :createMissing => true,
          :updateExisting => true
        },
        :screens => {
          :createMissing => true,
          :updateExisting => true
        },
        :templateLinkage => {
          :createMissing => true,
        },
        :templates => {
          :createMissing => true,
          :updateExisting => true
        },
        :templateScreens => {
          :createMissing => true,
          :updateExisting => true
        },
        :triggers => {
          :createMissing => true,
          :updateExisting => true,
          :deleteMissing => true
        }
      },
      :source => template,
      :format => 'xml'
      )
      puts "Import #{template_file} successful."
    rescue => e
      puts "Failed import #{template_file}"
      # puts e
    end
  end

  def group_list(groupid)
    if groupid == "all"
      grouplist = @zabbix.hostgroup.get(
        :output => "extend"
      )
    else
      grouplist = @zabbix.hostgroup.get(
        :groupids => groupid,
        :output => "extend"
      )
    end
    data = Array.new
    grouplist.each do |g|
      data << {:id => g['groupid'], :name => g['name']}
    end
    if data.length == 0
      msg = "GroupID #{groupid} not found.\n"
      puts msg
      msg
    else
      Formatador.display_compact_table(data, [:id, :name])
      data
    end
  end

  def action_list(actionid)
    if actionid == "all"
      actionlist = @zabbix.action.get(
        :output => "extend"
      )
    else
      actionlist = @zabbix.action.get(
        :actionids => actionid,
        :output => "extend"
      )
    end

    data = Array.new

    actionlist.each do |a|
      if a['status'] == "1"
        status = "disable"
      elsif a['status'] == "0"
        status = "enable"
      end

      case a['eventsource']
      when "0"
        eventsource = "Trigger"
      when "1"
        eventsource = "Discover"
      when "2"
        eventsource = "Auto Registration"
      when "3"
        eventsource = "Internal Event"
      end

      data << {:id => a['actionid'], :name => a['name'], :eventsource => eventsource, :status => status}
    end
    Formatador.display_compact_table(data, [:id, :name, :eventsource, :status])
    data
  end

  def action_enable(actionid)
    begin
      @zabbix.action.update(
        :actionid => actionid,
        :status => "0"
      )
      action_list(actionid)
    rescue => e
      msg = "ActionID #{actionid} not found.\n #{e}"
      puts msg
      msg
    end
  end

  def action_disable(actionid)
    begin
      @zabbix.action.update(
        :actionid => actionid,
        :status => "1"
      )
      action_list(actionid)
    rescue => e
      msg = "ActionID #{actionid} not found.\n #{e}"
      puts msg
      msg
    end
  end
end

def print_host_usage
  puts <<-EOS
Usage :
  #{$0} host list
  #{$0} host list (HOSTID)
  #{$0} host enable (HOSTID)
  #{$0} host disable (HOSTID)
  #{$0} host delete (HOSTID)
  EOS
  exit
end

def print_template_usage
  puts <<-EOS
Usage :
  #{$0} template list
  #{$0} template list (TEMPALTEID)
  #{$0} template export (TEMPALTEID)
  #{$0} template import (TEMPLATE FILENAME)
  EOS
  exit
end

def print_group_usage
  puts <<-EOS
Usage :
  #{$0} group list
  #{$0} group list (GROUPID)
  EOS
  exit
end

def print_action_usage
  puts <<-EOS
Usage :
  #{$0} action list
  #{$0} action list (ACTIONID)
  #{$0} action enable (ACTIONID)
  #{$0} action disable (ACTIONID)
  EOS
  exit
end

case opt1
when "host"
  case opt2
  when "list"
    if(!opt3)
      ZBX.new.host_list("all")
    else
      ZBX.new.host_list(opt3)
    end
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

when "template"
  case opt2
  when "list"
    if(!opt3)
      ZBX.new.template_list("all")
    else
      ZBX.new.template_list(opt3)
    end
  when "export"
    print_template_usage if(!opt3)
    ZBX.new.template_export(opt3)
  when "import"
    print_template_usage if(!opt3)
    ZBX.new.template_import(opt3)
  else
    print_template_usage
  end

when "group"
  case opt2
  when "list"
    if(!opt3)
      ZBX.new.group_list("all")
    else
      ZBX.new.group_list(opt3)
    end
  else
    print_group_usage
  end

when "action"
  case opt2
  when "list"
    if(!opt3)
      ZBX.new.action_list("all")
    else
      ZBX.new.action_list(opt3)
    end
  when "enable"
    print_action_usage if(!opt3)
    ZBX.new.action_enable(opt3)
  when "disable"
    print_action_usage if(!opt3)
    ZBX.new.action_disable(opt3)
  else
    print_action_usage
  end
end
