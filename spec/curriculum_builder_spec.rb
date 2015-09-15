require 'curriculum_builder'

describe CurriculumBuilder do
  let(:given_solution)          { CSV.read(File.expand_path('../fixtures/sample_solution.csv', __FILE__)) }
  let(:domain_order_file_path)  { File.expand_path('../fixtures/domain_order.csv', __FILE__) }
  let(:student_tests_file_path) { File.expand_path('../fixtures/student_tests.csv', __FILE__) }

  subject { described_class.new(domain_order_file_path, student_tests_file_path) }

  xit "builds a satisfactory curriculum plan" do
    solution = subject.plan
    expect(solution).to eq(given_solution)
  end
end
