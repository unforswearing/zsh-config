#!/bin/bash

declare -A set

# Add element to set
add_element() {
  local element=$1
  set["$element"]=1
}

# Remove element from set
remove_element() {
  local element=$1
  unset set["$element"]
}

# Check membership
is_member() {
  local element=$1
  if [[ -n ${set["$element"]} ]]; then
    return 0  # true
  else
    return 1  # false
  fi
}

# List elements
list_elements() {
  for element in "${!set[@]}"; do
    echo "$element"
  done
}

# Union of two sets
union() {
  declare -A set1=("${!1}")
  declare -A set2=("${!2}")
  declare -A result_set

  for element in "${!set1[@]}"; do
    result_set["$element"]=1
  done

  for element in "${!set2[@]}"; do
    result_set["$element"]=1
  done

  echo "${!result_set[@]}"
}

# Intersection of two sets
intersection() {
  declare -A set1=("${!1}")
  declare -A set2=("${!2}")
  declare -A result_set

  for element in "${!set1[@]}"; do
    if [[ -n ${set2["$element"]} ]]; then
      result_set["$element"]=1
    fi
  done

  echo "${!result_set[@]}"
}

# Difference of two sets
difference() {
  declare -A set1=("${!1}")
  declare -A set2=("${!2}")
  declare -A result_set

  for element in "${!set1[@]}"; do
    if [[ -z ${set2["$element"]} ]]; then
      result_set["$element"]=1
    fi
  done

  echo "${!result_set[@]}"
}

# Test the set functions
# add_element "apple"
# add_element "banana"
# add_element "cherry"

# echo "Set after adding elements:"
# list_elements

# remove_element "banana"
# echo "Set after removing 'banana':"
# list_elements

# is_member "apple" && echo "apple is a member" || echo "apple is not a member"
# is_member "banana" && echo "banana is a member" || echo "banana is not a member"

# declare -A set2
# set2=(["apple"]=1 ["date"]=1 ["elderberry"]=1)

# echo "Union of sets:"
# union set[@] set2[@]

# echo "Intersection of sets:"
# intersection set[@] set2[@]

# echo "Difference of sets:"
# difference set[@] set2[@]
