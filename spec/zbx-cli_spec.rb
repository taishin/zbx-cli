require_relative '../zbx-cli'


describe 'zabbix-cli' do
  let(:zbx) { ZBX.new }
  let(:exist_hostid) { 10084 }
  let(:non_exist_hostid) { 100 }

  it "message return hello" do
    expect(zbx.host_list(exist_hostid).first[:interface]).to match(/127\.0\.0\.1/)
  end

  describe 'enable host' do
    it "when HostID is exists" do
      expect(zbx.host_enable(exist_hostid).first[:status]).to eq "enable"
    end
    it "when HostID is not exists" do
      expect(zbx.host_enable(non_exist_hostid)).to match(/.*/)
    end
  end

  describe 'disable host' do
    it "when HostID is exists" do
      expect(zbx.host_disable(exist_hostid).first[:status]).to eq "disable"
    end
    it "when HostID is not exists" do
      expect(zbx.host_disable(non_exist_hostid)).to match(/.*/)
    end
  end
end
