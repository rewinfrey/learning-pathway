require 'csv'

class CurriculumBuilder
  attr_reader :domain_order_file_path, :student_tests_file_path

  # Ideally this constant would be configurable outside of this class
  # or passed in as an extra input parameter to the constructor.
  # This is the only assumed hard coded value for parsing the
  # domain_order.csv
  DOMAIN_POSITION = 0

  # Ideally this constant map would also be configurable outside of this
  # class or passed in as an extra input paramaeter, too.
  # Using this constant map, it becomes feasible to arbitrarily
  # order domains. Preschool, subdomains, or categorical domains
  # become possible to use in domain orders, without needing any code change.
  DOMAIN_TO_INTEGER = {
    "K" => 0
  }

  # Same configurability comment as DOMAIN_POSITION and DOMAIN_TO_INTEGER
  MAXIMUM_CURRICULUM_LENGTH = 5

  def initialize(domain_order_file_path, student_tests_file_path)
    @domain_order_file_path = domain_order_file_path
    @student_tests_file_path = student_tests_file_path
  end

  def domain_transition_map
    @domain_transition_map ||= generate_domain_transition_map
  end

  def domain_order_map
    @domain_order_map ||= generate_domain_order_map
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

  private

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

  def generate_domain_transition_map
    domains = []
    # Unfortunately Ruby's Enumerator module #reduce or #each_with_index has problems with the IO stream when used with CSV.foreach
    CSV.foreach(domain_order_file_path) { |domain_standard_row| domains << domain_standard_row[DOMAIN_POSITION] }

    sorted_domains = domains.sort do |x, y|
      x = domain_to_integer(x)
      y = domain_to_integer(y)
      x <=> y
    end

    sorted_domains.each_with_index.reduce({}) do |transition_map, (domain, index)|
      transition_map[domain] = sorted_domains[index.next]
      transition_map
    end
  end

  def generate_domain_order_map
    domain_order = CSV.read(domain_order_file_path)
    domain_order.each_with_index.reduce({}) do |domain_order_map, (domain_row, domain_order_index)|
      domain = domain_for_row(domain_row)
      domain_row.each_with_index do |domain_or_standard, domain_or_standard_index|
        # ignore the domain designation in each row
        next if domain?(domain_or_standard)

        standard = domain_or_standard

        # I did not want to make hard assumptions about the location
        # of the domain in each row of a given domain order csv file.
        if next_standard = next_standard_for_row(domain_row, domain_or_standard_index.next)
          domain_order_map["#{domain}.#{standard}"] = "#{domain}.#{next_standard}"
        elsif next_domain = domain_transition_map[domain]
          # I did not want to assume the domain order csv would
          # list domains in the correct oder.
          next_domain_row = next_domain_row_for_target_domain(next_domain, domain_order, domain_order_index.next)
          domain_order_map["#{domain}.#{standard}"] = "#{next_domain}.#{next_standard_for_row(next_domain_row, 0)}"
        else
          domain_order_map["#{domain}.#{standard}"] = nil
        end
      end
      domain_order_map
    end
  end

  def domain?(item)
    domain_transition_map.has_key?(item)
  end

  def domain_for_row(domain_standard_row)
    domain_standard_row.find { |domain_or_standard| domain?(domain_or_standard) }
  end

  def next_standard_for_row(domain_standard_row, index)
    domain_standard_row[(index)..-1].find { |domain_or_standard| !domain?(domain_or_standard) }
  end

  def next_domain_row_for_target_domain(target_domain, domain_order, domain_order_index)
    # Optimistic lookup of target domain assuming domain order csv lists domains in correct order
    next_domain_row = domain_order[(domain_order_index)..-1].find { |domain_row| domain_for_row(domain_row) == target_domain }
    return next_domain_row if next_domain_row
    # Pessimistic lookup of target domain if optimistic lookup fails
    next_domain_row= domain_order.find { |domain_row| domain_for_row(domain_row) == target_domain }
  end

  def domain_to_integer(domain)
    DOMAIN_TO_INTEGER.fetch(domain, domain).to_i
  end
end
