require 'domain_mapper'

describe DomainMapper do
  let(:domain_order_file_path)  { File.expand_path('../fixtures/domain_order.csv', __FILE__) }

  subject { described_class.new(domain_order_file_path) }

  describe "#domain_to_integer" do
    it "returns 0 integer value for special domain" do
      k_domain = subject.domain_to_integer("K")
      expect(k_domain).to eq(0)
    end
  end

  describe "#domain_transition_map" do
    it "builds a hash map illustrating the domain transitions" do
      expected_domain_transition_map =  {
        "K" => "1",
        "1" => "2",
        "2" => "3",
        "3" => "4",
        "4" => "5",
        "5" => "6",
        "6" => nil
      }

      domain_transition_map = subject.domain_transition_map

      expect(domain_transition_map).to eq(expected_domain_transition_map)
    end
  end

  describe "#domain_order_map" do
    it "builds a hash map illustrating the progression of domains and their standards" do
      expected_domain_order_map = {
        "K.RF"=>"K.RL", "K.RL"=>"K.RI", "K.RI"=>"1.RF", "1.RF"=>"1.RL",
        "1.RL"=>"1.RI", "1.RI"=>"2.RF", "2.RF"=>"2.RI", "2.RI"=>"2.RL",
        "2.RL"=>"2.L", "2.L"=>"3.RF", "3.RF"=>"3.RL", "3.RL"=>"3.RI",
        "3.RI"=>"3.L", "3.L"=>"4.RI", "4.RI"=>"4.RL", "4.RL"=>"4.L",
        "4.L"=>"5.RI", "5.RI"=>"5.RL", "5.RL"=>"5.L", "5.L"=>"6.RI",
        "6.RI"=>"6.RL", "6.RL"=>nil
      }

      domain_order_map = subject.domain_order_map

      expect(domain_order_map).to eq(expected_domain_order_map)
    end
  end

end
