require 'csv'

class CurriculumBuilder
  attr_reader :domain_order_file_path, :student_tests_file_path

  def initialize(domain_order_file_path, student_tests_file_path)
    @domain_order_file_path = domain_order_file_path
    @studnet_tests_file_path = student_tests_file_path
  end

  def plan
    []
  end
end
