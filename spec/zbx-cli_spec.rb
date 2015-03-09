require_relative '../zbx-cli'


describe 'zabbix-cli' do
  let(:zbx) { ZBX.new }

  describe 'host' do
    let(:exist_hostid) { 10084 }
    let(:non_exist_hostid) { 100 }

    describe 'enable host' do
      it "when HostID is exists" do
        expect(zbx.host_enable(exist_hostid).first[:status]).to eq "enable"
      end
      it "when HostID is not exists" do
        expect(zbx.host_enable(non_exist_hostid)).to match(/HostID #{non_exist_hostid} not found\./)
      end
    end

    describe 'disable host' do
      it "when HostID is exists" do
        expect(zbx.host_disable(exist_hostid).first[:status]).to eq "disable"
      end
      it "when HostID is not exists" do
        expect(zbx.host_disable(non_exist_hostid)).to match(/HostID #{non_exist_hostid} not found\./)
      end
    end
  end

  describe 'template' do
    let(:exist_templateid) { 10001 }
    let(:non_exist_templateid) { 100 }

    describe "list template" do
      it "when TemplateID is exists" do
        expect(zbx.template_list(exist_templateid).first[:name]).to eq "Template OS Linux"
      end
      it "when TemplateID is not exists" do
        expect(zbx.template_list(non_exist_templateid)).to eq "TemplateID #{non_exist_templateid} not found.\n"
      end
    end
  end

  describe 'group' do
    let(:exist_groupid) { 1 }
    let(:non_exist_groupid) { 10000 }

    describe "list group" do
      it "when GroupID is exists" do
        expect(zbx.group_list(exist_groupid).first[:name]).to eq "Templates"
      end
      it "when GroupID is not exists" do
        expect(zbx.group_list(non_exist_groupid)).to eq "GroupID #{non_exist_groupid} not found.\n"
      end
    end
  end


end
