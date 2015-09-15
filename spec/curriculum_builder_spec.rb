require 'curriculum_builder'

describe CurriculumBuilder do
  let(:given_solution)          { CSV.read(File.expand_path('../fixtures/sample_solution.csv', __FILE__)) }
  let(:domain_order_file_path)  { File.expand_path('../fixtures/domain_order.csv', __FILE__) }
  let(:student_tests_file_path) { File.expand_path('../fixtures/student_tests.csv', __FILE__) }

  subject { described_class.new(domain_order_file_path, student_tests_file_path) }

  describe "#plan" do
    it "builds a satisfactory curriculum plan" do
      solution = subject.plan
      expect(solution).to eq(given_solution)
    end
  end

  describe "#minimum_domain_standard?" do
    it "returns true if the test standard and test domain occur prior to the base standard and base domain" do
      test_domain = "K"
      test_standard = "RI"
      base_domain = "2"
      base_standard = "RF"

      result = subject.minimum_domain_standard?(test_standard, test_domain, base_standard, base_domain)

      expect(result).to be_truthy
    end
  end

  describe "#minimum_domain_standard" do
    it "returns the minimum domain and standard for a given student's test scores" do
      standard_domain_map = {
        "RF" => "2",
        "RL" => "3",
        "RI" => "K",
        "L" => "3"
      }

      minimum_map = subject.minimum_domain_standard(standard_domain_map)

      expect(minimum_map[:minimum_domain]).to eq("K")
      expect(minimum_map[:minimum_standard]).to eq("RI")
    end

    it "ensures the minimum domain and standard are valid according to the given domain order" do
      invalid = { "L" => "K" }
      standard_domain_map = {
        "RF" => "2",
        "RL" => "3",
        "RI" => "3"
      }.merge(invalid)

      minimum_map = subject.minimum_domain_standard(standard_domain_map)

      expect(minimum_map[:minimum_domain]).to eq("2")
      expect(minimum_map[:minimum_standard]).to eq("RF")
    end
  end

  describe "#build_curriculum" do
    it "returns a curriculum plan for a given student's scores" do
      student_map = {
        "Student Name" => "Albin Stanton",
        :minimum_domain => "K",
        :minimum_standard => "RI",
        :standard_domain_map => {
          "RF" => "2",
          "RL" => "3",
          "RI" => "K",
          "L" => "3"
        }
      }
      expected_plan = ["K.RI", "1.RI", "2.RF", "2.RI", "3.RF"]

      curriculum_plan = subject.build_curriculum(student_map)

      expect(curriculum_plan).to eq(expected_plan)
    end
  end
end
