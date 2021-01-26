# First let's do some general
# code block practice

# Given a hash, return
# all values that are divisble
# by 2. Assume values are ints
# Use a code block.
def evens_string(hash)
    str = ""
    hash.values.each{|v|
        if v % 2 == 0
            str = str + v.to_s
        end
    }
    return str
end

# Now let's up the stakes
# Given an array of elements
# return a new array whose
# elements have been processed
# by the code block

# If no code block is given,
# simply return an array where
# every element is increased by 1
def map_w_code_block(arr)
    if block_given?
        for i in 0...arr.length
            arr[i] = yield(arr[i])
        end
    else
        arr.collect! {|x| x + 1}
    end
    return arr
end


# Time for some regex practice!
# Write a regular expression to
# capture a time.

# Times are defined in the following
# way:
# A 2 digit hour (from 01 to 12)
# A 2 digit minute (from 00 to 59)
# A 2 digit second (from 00 to 59)
# A two letter indication : A.M., P.M.
# EX. 12:31:59 P.M.

# If I give you a valid time:
# return the string "It is _ _",
# where the first blank is replaced
# by the hour, and the second blank
# is replaced by A.M. or P.M.
# EX. "It is 12 P.M." (It doesn't
# matter if it's 12:59:59 - It's still
# 12 for us)
# If I give you ANYTHING else
# return the string "Invalid"
def time_teller(time_str)
    if time_str =~ /^(0[1-9]|1[0-2]):[0-5][0-9]:[0-5][0-9] (A\.M\.|P\.M\.)$/
        hour = $1
        am_pm = $2
        return "It is #{hour} #{am_pm}"
    else
        return "Invalid"
    end
end


# Alright, we've got three basic
# exercises out of the way, let's
# put it all together!

class Grader

    # You'll be given a file of strings
    # Each line has a first name and last name
    # (Start with capital, then lowercase),
    # followed by a comma and then their grade
    # a number from 0 to 100
    # EX. "Frodo Baggins, 98"
    def initialize(filename)
        @hash = Hash.new
        File.foreach(filename) do |line|
            if line =~ /^(.*), ([1-9]?[0-9]|100)$/
                name = $1
                grade = $2.to_i
                new_pair = {name => grade}
                @hash.merge!(new_pair)
            end
        end
    end

    # Because 330 is so great,
    # we'll sometimes spontaneously
    # give all students some extra
    # credit, defined by a code block
    # we pass in. Update your data
    # to add this extra credit
    def add_extra_credit()
        @hash.each {|name, grade| @hash[name] = yield(grade) }
    end

    # Return the grade for the
    # specified student
    def get_grades_for_student(student_Name)
        return @hash[student_Name]
    end
end
