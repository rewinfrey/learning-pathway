require 'csv'
require 'domain_mapper'

class CurriculumBuilder
  attr_reader :domain_order_file_path, :student_tests_file_path

  # Ideally this constant would be configurable in a separate
  # file or as part of an initializer, or perhaps passed in as
  # an input parameter.
  MAXIMUM_CURRICULUM_LENGTH = 5

  def initialize(domain_order_file_path, student_tests_file_path)
    @domain_order_file_path = domain_order_file_path
    @student_tests_file_path = student_tests_file_path
  end

  def plan
    student_maps = []
    headers = nil

    CSV.foreach(student_tests_file_path) do |row|
      headers ||= row
      next if headers == row

      student_map = student_map(headers, row)
      student_map[:curriculum] = build_curriculum(student_map.merge(minimum_domain_standard(student_map[:standard_domain_map])))

      student_maps << student_map
    end

    student_maps.map { |student| [student[headers.first], [student[:curriculum]]].flatten }
  end

  private

  # Ideally, passing this dependency in via the constructor makes
  # it easier to test against (where applicable), and enables the ability
  # for CurriculumBuilder to depend on different types of domain mapper
  # abstractions (dependency inversion principle) at run time in the event
  # that some domain orders require special logic not supported by
  # the generic DomainMapper class.
  def domain_mapper
    @domain_mapper ||= DomainMapper.new(domain_order_file_path)
  end

  def domain_transition_map
    domain_mapper.domain_transition_map
  end

  def domain_order_map
    domain_mapper.domain_order_map
  end

  def domain_to_integer(domain)
    domain_mapper.domain_to_integer(domain)
  end

  def build_curriculum(student_map)
    curriculum = []
    applicable = true
    domain_standard = "#{student_map[:minimum_domain]}.#{student_map[:minimum_standard]}"

    while(curriculum.count < MAXIMUM_CURRICULUM_LENGTH && domain_standard) do
      curriculum << domain_standard if applicable

      domain_standard = domain_order_map[domain_standard]

      applicable = domain_standard_applicable?(domain_standard, student_map[:standard_domain_map])
    end

    curriculum
  end

  def minimum_domain_standard(student_standards_domain_map)
    student_standards_domain_map.reduce({}) do |minimum_map, standard_domain|
      standard, domain = most_applicable_domain_standard(standard_domain)

      minimum_map[:minimum_standard] ||= standard
      minimum_map[:minimum_domain]   ||= domain

      if minimum_domain_standard?(standard, domain, minimum_map[:minimum_standard], minimum_map[:minimum_domain])
        minimum_map = {
          :minimum_standard => standard,
          :minimum_domain   => domain
        }
      end

      minimum_map
    end
  end

  def minimum_domain_standard?(test_standard, test_domain, base_standard, base_domain)
    earlier_domain?(test_domain, base_domain) ||
      earlier_domain_standard?(test_domain, test_standard, base_domain, base_standard)
  end

  def most_applicable_domain_standard(standard_domain)
    standard, domain = standard_domain
    # Return immediately if the given standard and domain exist within the given domain order
    return([standard, domain]) if domain_standard_exists?(domain, standard)

    temp_domain = domain
    while(temp_domain != nil) do
      temp_domain = domain_transition_map[temp_domain]
      break if domain_standard_exists?(temp_domain, standard)
    end

    if temp_domain == nil
      return [standard, domain]
    else
      return [standard, temp_domain]
    end
  end

  def domain_standard_exists?(domain, standard)
    domain_order_map.has_key?("#{domain}.#{standard}")
  end

  def student_map(student_headers, student_record)
    {
      student_headers.first => student_record.first,
      :standard_domain_map => Hash[student_headers[1..-1].zip(student_record[1..-1])]
    }
  end

  def domain_standard_applicable?(domain_standard, student_standard_domain_map)
    return false unless domain_standard
    domain, standard = domain_standard.split(".")
    domain_to_integer(student_standard_domain_map[standard]) <= domain_to_integer(domain)
  end

  def earlier_domain?(test_domain, base_domain)
    domain_to_integer(test_domain) < domain_to_integer(base_domain)
  end

  def earlier_domain_standard?(test_domain, test_standard, base_domain, base_standard)
    next_domain_standard = domain_order_map["#{test_domain}.#{test_standard}"]

    # guard against domain / standard combinations that are not within the provided sequence
    return false if next_domain_standard.nil?

    test_domain, test_standard = next_domain_standard.split(".")

    # decided to use a while loop rather than recurse (not sure how many standards might ever be in a domain and don't want to risk blowing the stack)
    while((test_domain == base_domain) && ((test_standard != base_standard))) do
      test_domain, test_standard = domain_order_map["#{test_domain}.#{test_standard}"].split(".")
    end

    # returns true for a domain / standard combination that matches the same domain as the base_domain and the standard matches the base_standard
    # (indicating that the test_standard occurs before the base_standard in the supplied domain / standard sequence)
    # otherwise returns false meaning that the test_domain / test_standard do not occur prior to the base_domain / base_standard in the provided sequence
    return (test_domain == base_domain && test_standard == base_standard)
  end
end
